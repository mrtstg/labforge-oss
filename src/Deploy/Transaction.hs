{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE RecordWildCards    #-}
module Deploy.Transaction
  ( planTransactionStages
  , planTransactionActions
  , getVMIDRange
  , executeTransaction
  ) where

import           Api.Proxmox.Client
import           Api.Proxmox.Models
import           Api.Proxmox.Models.Network
import           Api.Proxmox.Models.SDNNetwork
import           Api.Proxmox.Models.SDNZone
import           Api.Proxmox.Models.VM
import           Api.Proxmox.Models.VMClone
import           Api.Proxmox.Models.VMConfig
import           Api.Retry
import           Control.Concurrent
import           Control.Monad.IO.Class
import           Control.Monad.Trans.Class
import           Control.Monad.Trans.Except
import           Control.Monad.Trans.State
import           Control.Monad.Trans.Writer
import           Data.Aeson                    (Value (..))
import           Data.Functor                  ((<&>))
import           Data.Functor.Identity
import           Data.List                     (nub, sortOn)
import           Data.Map                      (Map)
import qualified Data.Map                      as M
import           Data.Maybe
import           Data.Models.Config
import           Data.Models.Config.Deploy
import           Data.Models.Config.Network
import           Data.Models.Config.Template
import           Data.Models.Config.VM
import           Data.Models.Transaction
import qualified Data.Text                     as T
import           Deploy.Types
import           System.Log.Logger

loggerName = "ProxmoxCompose.Transaction"

vmDevicePresent :: String ->ProxmoxResponse (Maybe ProxmoxVMConfig) -> Bool
vmDevicePresent _ (ProxmoxResponse { proxmoxData = Nothing }) = False
vmDevicePresent deviceName (ProxmoxResponse { proxmoxData = Just cfg }) = ((deviceName `elem`) . M.keys . vmConfigMap) cfg

vmNetworksEmpty :: ProxmoxResponse (Maybe ProxmoxVMConfig) -> Bool
vmNetworksEmpty (ProxmoxResponse { proxmoxData = Nothing }) = False
vmNetworksEmpty (ProxmoxResponse { proxmoxData = Just cfg }) = (null . vmConfigNetworkNumbers) cfg

-- function for waitForClient, checks vm by id and its power
vmStateIs :: ProxmoxResponse ProxmoxVMStatusWrapper -> ProxmoxVMStatus -> Bool
vmStateIs (ProxmoxResponse { proxmoxData = ProxmoxVMStatusWrapper status }) = (==status)

vmExists :: Int -> M.Map Int ProxmoxVM -> Bool
vmExists vmid vmMap = isJust $ M.lookup vmid vmMap

vmNotExists :: Int -> M.Map Int ProxmoxVM -> Bool
vmNotExists vmid vmMap = not $ vmExists vmid vmMap

vmUnlocked :: ProxmoxResponse (Maybe ProxmoxVMConfig) -> Bool
vmUnlocked (ProxmoxResponse Nothing _) = False
vmUnlocked (ProxmoxResponse { proxmoxData = Just ProxmoxVMConfig { vmLock = vmLock }}) = isNothing vmLock

sdnNetworkExists :: String -> ProxmoxResponse [ProxmoxNetwork] -> Bool
sdnNetworkExists vnetName (ProxmoxResponse { proxmoxData = networks }) = any (\x -> proxmoxNetworkType x == Vnet && proxmoxNetworkInterface x == vnetName) networks

-- looks up for transaction data and deploy config for vmid
getVMID :: String -> TransactionData -> DeployConfig -> Maybe Int
getVMID vmName (TransactionData vmIDMap) (DeployConfig {deployVMs=vms }) = do
  case M.lookup vmName vmIDMap of
    (Just vmid) -> Just vmid
    Nothing -> case filter ((==vmName) . configVMName) vms of
      []     -> Nothing
      (vm:_) -> configVMID vm

executeTransactionAction :: TransactionAction -> StatefulTransactionM ()
executeTransactionAction (AssignVMID vmName) = do
  (TransactionState { .. }) <- lift get
  (TransactionData vmIDMap) <- transactionDataGetF
  case M.lookup vmName vmIDMap of
    (Just _) -> (liftIO . warningM loggerName) $ "VM " <> vmName <> " already has allocated VMID. Skipping."
    Nothing -> do
      vmid <- transactionAllocateVMIDF
      let ntData = TransactionData (M.insert vmName vmid vmIDMap)
      () <- transactionDataSetF ntData
      return ()
executeTransactionAction (UnassignVMID vmName) = do
  (TransactionState { .. }) <- lift get
  d@(TransactionData vmIDMap) <- transactionDataGetF
  case M.lookup vmName vmIDMap of
    Nothing -> (liftIO . warningM loggerName) $ "VM " <> vmName <> " has no allocated VMID. Skipping."
    (Just _) -> do
      let ntData = d { transactionIDMap = M.delete vmName vmIDMap }
      () <- transactionDataSetF ntData
      return ()
executeTransactionAction (DestroyVM vmName) = do
  (TransactionState { transactionDeployConfig = deployConfig@(DeployConfig {deployParameters = (DeployParams { deployNodeName = nodeName }) }),.. }) <- lift get
  data' <- transactionDataGetF
  case getVMID vmName data' deployConfig of
    Nothing -> (liftIO . warningM loggerName) $ "VM " <> vmName <> " has no allocated VMID"
    (Just vmid) -> do
      vmMap <- (liftIO . defaultRetryClient' transactionProxmoxState) getActiveNodesVMMap >>= defaultClientErrorWrapper
      if vmExists vmid vmMap then do
        _ <- (liftIO . defaultRetryClient' transactionProxmoxState) (deleteVM' nodeName vmid defaultProxmoxVMDeleteRequest)
        deleteResult <- liftIO $ waitForClient
          60_000_000
          ("VM " <> show vmid <> " still exists. Waiting...")
          5
          1_000_000
          (defaultRetryClient' transactionProxmoxState getActiveNodesVMMap)
          (vmNotExists vmid)
        case deleteResult of
          (Left e) -> throwE (ClientError e)
          (Right True) -> (liftIO . infoM loggerName) $ "VM " <> show vmName <> " is deleted"
          (Right False) -> throwE (VMDeleteError vmid)
      else (liftIO . warningM loggerName) $ "VM " <> show vmName <> " is not found by its VMID (" <> show vmid <> ")"
executeTransactionAction (StopVM vmName) = do
  (TransactionState { transactionDeployConfig = deployConfig@(DeployConfig {deployParameters = (DeployParams { deployNodeName = nodeName }) }),.. }) <- lift get
  data' <- transactionDataGetF
  case getVMID vmName data' deployConfig of
    Nothing -> (liftIO . warningM loggerName) $ "VM " <> vmName <> " has no allocated VMID"
    (Just vmid) -> do
      vmMap' <- (liftIO . defaultRetryClient' transactionProxmoxState) getActiveNodesVMMap
      case vmMap' of
        (Left e) -> throwE (ClientError e)
        (Right vmMap) -> do
          case M.lookup vmid vmMap of
            Nothing -> (liftIO . warningM loggerName) $ "VM with VMID " <> show vmid <> " not found."
            _ -> do
              powerResult <- liftIO $ waitForClient
                60_000_000
                ("VM " <> show vmid <> " is not powered on. Waiting...")
                15
                1_000_000
                (defaultRetryClient' transactionProxmoxState (stopVM nodeName vmid >> (liftIO . threadDelay) 5_000_000 >> getVMPower nodeName vmid))
                (`vmStateIs` VMStopped)
              case powerResult of
                (Left e) -> throwE (ClientError e)
                (Right True) -> (liftIO . infoM loggerName) $ "Turned off VM " <> vmName <> "(#" <> show vmid <> ")"
                (Right False) -> (liftIO . warningM loggerName) $ "Failed to stop VM " <> vmName <> "(#" <> show vmid <> ")"
executeTransactionAction (StartVM vmName) = do
  -- TODO: "wait for" function
  (TransactionState { transactionDeployConfig = deployConfig@(DeployConfig {deployParameters = (DeployParams { deployNodeName = nodeName }) }),.. }) <- lift get
  data' <- transactionDataGetF
  case getVMID vmName data' deployConfig of
    Nothing -> throwE (MachineHasNoID vmName)
    (Just vmid) -> do
      vmMap <- (liftIO . defaultRetryClient' transactionProxmoxState) getActiveNodesVMMap >>= defaultClientErrorWrapper
      case M.lookup vmid vmMap of
        Nothing -> (liftIO . warningM loggerName) $ "VM with VMID " <> show vmid <> " not found."
        _ -> do
          powerResult <- liftIO $ waitForClient
            60_000_000
            ("VM " <> show vmid <> " is not powered on. Waiting...")
            10
            1_000_000
            (defaultRetryClient' transactionProxmoxState (startVM nodeName vmid >> (liftIO . threadDelay) 5_000_000 >> getVMPower nodeName vmid))
            (`vmStateIs` VMRunning)
          case powerResult of
            (Left e) -> throwE (ClientError e)
            (Right True) -> (liftIO . infoM loggerName) $ "Turned on VM " <> vmName <> "(#" <> show vmid <> ")"
            (Right False) -> (liftIO . warningM loggerName) $ "Failed to start VM " <> vmName <> "(#" <> show vmid <> ")"
executeTransactionAction (AttachNetwork vmName networkConfig) = do
  (TransactionState { transactionDeployConfig = deployConfig@(DeployConfig {deployParameters = (DeployParams { deployNodeName = nodeName }) }),.. }) <- lift get
  data' <- transactionDataGetF
  case getVMID vmName data' deployConfig of
    Nothing -> throwE (MachineHasNoID vmName)
    (Just vmid) -> do
      vmMap <- (liftIO . defaultRetryClient' transactionProxmoxState) getActiveNodesVMMap >>= defaultClientErrorWrapper
      case M.lookup vmid vmMap of
        Nothing -> (liftIO . warningM loggerName) $ "VM with VMID " <> show vmid <> " not found."
        _ -> do
          case formatConfigVMNetwork networkConfig of
            Nothing -> throwE (UnknownError $ "Failed to format network device string: " <> show networkConfig)
            (Just (deviceName, deviceConfig)) -> do
              _ <- (liftIO . defaultRetryClient' transactionProxmoxState) (putVMConfig nodeName vmid (M.fromList [(deviceName, (String . T.pack) deviceConfig)])) >>= defaultClientErrorWrapper
              _ <- liftIO $ waitForClient
                60_000_000
                ("Waiting for configuration change of VM " <> show vmid)
                10
                1_000_000
                (defaultRetryClient' transactionProxmoxState $ getVMConfig nodeName vmid)
                (vmDevicePresent deviceName)
              pure ()
executeTransactionAction (RemoveNetworks vmName) = do
  (TransactionState { transactionDeployConfig = deployConfig@(DeployConfig {deployParameters = (DeployParams { deployNodeName = nodeName }) }),.. }) <- lift get
  data' <- transactionDataGetF
  case getVMID vmName data' deployConfig of
    Nothing -> throwE (MachineHasNoID vmName)
    (Just vmid) -> do
      vmMap <- (liftIO . defaultRetryClient' transactionProxmoxState) getActiveNodesVMMap >>= defaultClientErrorWrapper
      case M.lookup vmid vmMap of
        Nothing -> (liftIO . warningM loggerName) $ "VM with VMID " <> show vmid <> " not found."
        _ -> do
          (ProxmoxResponse { proxmoxData = vmCfg'}) <- (liftIO . defaultRetryClient' transactionProxmoxState) (getVMConfig nodeName vmid) >>= defaultClientErrorWrapper
          case vmCfg' of
            Nothing -> throwE (VMConfigIsNotFound vmName)
            (Just vmCfg) -> do
              _ <- (liftIO . defaultRetryClient' transactionProxmoxState) (deleteVMConfig nodeName vmid (map (\x -> "net" <> show x) (vmConfigNetworkNumbers vmCfg)))
              _ <- liftIO $ waitForClient
                60_000_000
                ("Waiting for configuration change of VM " <> show vmid)
                10
                1_000_000
                (defaultRetryClient' transactionProxmoxState $ getVMConfig nodeName vmid)
                vmNetworksEmpty
              pure ()
executeTransactionAction (CloneVM params@(ProxmoxVMCloneParams { proxmoxVMCloneName = vmName',.. })) = do
  let vmName = T.unpack $ fromJust vmName'
  (TransactionState { transactionDeployConfig = deployConfig@(DeployConfig {deployTemplates = templates}),.. }) <- lift get
  data' <- transactionDataGetF
  -- getting some overengineering with passing VMID from clone params
  -- but it is used in cloning, so idk at least now
  case getVMID vmName data' deployConfig of
    Nothing -> throwE (MachineHasNoID vmName)
    (Just vmid) -> do
      nodeMap <- (liftIO . defaultRetryClient' transactionProxmoxState) getActiveNodeVMNodeMap >>= defaultClientErrorWrapper
      case M.lookup vmid nodeMap of
        (Just _) -> (liftIO . warningM loggerName) $ "VM #" <> show vmid <> " already exists!"
        Nothing -> do
          case M.lookup proxmoxVMCloneVMID nodeMap of
            Nothing -> case filter ((==proxmoxVMCloneVMID) . configTemplateID) templates of
              (template:_) -> throwE (TemplateNodeNotFound template)
              []           -> error "unreachable"
            (Just templateNodeName) -> do
              let fullParams = params { proxmoxVMCloneNewID = vmid }
              cloneRes' <- (liftIO . defaultRetryClient' transactionProxmoxState) $ cloneVM (T.pack templateNodeName) proxmoxVMCloneVMID fullParams
              case cloneRes' of
                (Left e) -> throwE (ClientError e)
                (Right _) -> do
                  (liftIO . infoM loggerName) "VM is cloned, awaiting for unlocking VM..."
                  unlockResult <- liftIO $ waitForClient
                    60_000_000
                    ("VM " <> show vmid <> " is locked. Waiting...")
                    120
                    1_000_000
                    (defaultRetryClient' transactionProxmoxState $ getVMConfig (fromJust proxmoxVMCloneTarget) vmid)
                    vmUnlocked
                  case unlockResult of
                    (Left e)      -> throwE (ClientError e)
                    (Right False) -> throwE (VMLocked proxmoxVMCloneNewID)
                    _             -> pure ()
executeTransactionAction (TransactionDelayAfter secondsPause action) = do
  () <- executeTransactionAction action
  (liftIO . threadDelay . (* 1_000_000)) secondsPause
executeTransactionAction (DeploySDNNetwork networkCreate@(ProxmoxSDNNetworkCreate { sdnNetworkCreateName = vnetName })) = do
  (TransactionState { transactionDeployConfig = (DeployConfig {deployParameters = (DeployParams { deployNodeName = nodeName }) }),.. }) <- lift get
  bridgesResponse <- (liftIO . defaultRetryClient' transactionProxmoxState) (getNodeNetworks nodeName (Just AnyBridge)) >>= defaultClientErrorWrapper
  if sdnNetworkExists vnetName bridgesResponse then
    (liftIO . warningM loggerName) $ "SDN network " <> show vnetName <> " already exists"
  else do
    (liftIO . infoM loggerName) $ "Creating SDN network " <> show vnetName
    _ <- (liftIO . defaultRetryClient' transactionProxmoxState) (createSDNNetwork networkCreate) >>= defaultClientErrorWrapper
    (liftIO . infoM loggerName) $ "Applying SDN settings"
    _ <- (liftIO . defaultRetryClient' transactionProxmoxState) applySDNSettings
    bridgeResult <- liftIO $ waitForClient
      60_000_000
      ("SDN network " <> show vnetName <> " is not created. Waiting...")
      20
      1_000_000
      (defaultRetryClient' transactionProxmoxState $ getNodeNetworks nodeName (Just AnyBridge))
      (sdnNetworkExists vnetName)
    case bridgeResult of
      (Left e) -> throwE (ClientError e)
      (Right True) -> (liftIO . infoM loggerName) $ "Created SDN network " <> show vnetName
      (Right False) -> throwE (SDNVnetNotFound vnetName)
executeTransactionAction (DestroySDNNetwork (ProxmoxSDNNetworkCreate { sdnNetworkCreateName = vnetName })) = do
  (TransactionState { transactionDeployConfig = (DeployConfig {deployParameters = (DeployParams { deployNodeName = nodeName }) }),.. }) <- lift get
  bridgesResponse <- (liftIO . defaultRetryClient' transactionProxmoxState) (getNodeNetworks nodeName (Just AnyBridge)) >>= defaultClientErrorWrapper
  if not (sdnNetworkExists vnetName bridgesResponse) then
    (liftIO . warningM loggerName) $ "SDN network " <> show vnetName <> " does not exists"
  else do
    (liftIO . infoM loggerName) $ "Deleting SDN network " <> show vnetName
    _ <- (liftIO . defaultRetryClient' transactionProxmoxState) (deleteSDNNetwork (T.pack vnetName)) >>= defaultClientErrorWrapper
    (liftIO . infoM loggerName)$ "Applying SDN settings"
    _ <- (liftIO . defaultRetryClient' transactionProxmoxState) applySDNSettings
    bridgeResult <- liftIO $ waitForClient
      60_000_000
      ("SDN network " <> show vnetName <> " is existing. Waiting...")
      20
      1_000_000
      (defaultRetryClient' transactionProxmoxState $ getNodeNetworks nodeName (Just AnyBridge))
      (not . sdnNetworkExists vnetName)
    case bridgeResult of
      (Left e) -> throwE (ClientError e)
      (Right True) -> (liftIO . infoM loggerName) $ "Deleted SDN network " <> show vnetName
      (Right False) -> throwE (SDNVnetDeleteError vnetName)
executeTransactionAction _ = do
  (liftIO . infoM loggerName) "This stage is not supported now."
  pure ()

executeTransaction :: StatefulTransactionM ()
executeTransaction = do
  (TransactionState { .. }) <- lift get
  case transactionActions of
    [] -> pure ()
    (action:stages) -> do
      (liftIO . infoM loggerName) $ "Executing stage " <> show action
      () <- executeTransactionAction action
      oldState <- lift get
      lift $ put (oldState { transactionActions = stages })
      executeTransaction

getVMIDRange :: Int -> [Int] -> [Int]
getVMIDRange startVMID usedVMID = filter (`notElem` usedVMID) [startVMID..999999999]

planTransactionStages :: DeployConfig -> DeployTarget -> [TransactionStage]
planTransactionStages (DeployConfig { deployVMs=vms, deployTemplates=templates, deployNetworks=networks}) target = let
  f :: WriterT [TransactionStage] Identity ()
  f = do
    tell $ map TemplateExists templates
    tell $ map NetworkExists networks
    tell $ map VMExists vms
    let networkCleanVM = nub $ (filter (null . fromJust . configVMNetworks) $ filter (isJust . configVMNetworks) vms) ++ filter configVMCleanNetworks vms
    tell $ map (NetworksRemoved . configVMName) networkCleanVM
    tell $ foldMap generateNetworks vms
  f' :: WriterT [TransactionStage] Identity ()
  f' = do
    tell $ map VMNotExists (reverse vms)
    tell $ map NetworkNotExists (reverse networks)

  enumerateNetworks :: [Int] -> [ConfigVMNetwork] -> [ConfigVMNetwork] -> [ConfigVMNetwork]
  enumerateNetworks _ acc [] = reverse acc
  enumerateNetworks takenNumbers acc (net:nets) = do
    let numberRange = filter (`notElem` takenNumbers) [0..31]
    case configVMNetworkNumber net of
      (Just _) -> enumerateNetworks takenNumbers (net:acc) nets
      Nothing -> do
        case take 1 numberRange of
          [] -> error "Network ID overflow!"
          (netID:_) -> enumerateNetworks (netID:takenNumbers) (net { configVMNetworkNumber = Just netID }:acc) nets

  generateNetworks :: ConfigVM -> [TransactionStage]
  generateNetworks (TemplatedConfigVM { configVMName = vmName, configVMNetworks = nets' }) = do
    case nets' of
      Nothing -> []
      (Just nets) -> do
        let enumNets = enumerateNetworks (map (fromJust . configVMNetworkNumber) (filter (isJust . configVMNetworkNumber) nets)) [] nets
        map (NetworkConnected vmName) enumNets
  generateNetworks (RawVM {}) = [] -- TODO: add support
  in (snd . runIdentity . runWriterT) (if target == Deploy then f else f')
--(DeployConfig { deployNetworks = configNetworks, deployTemplates = vmTemplates, deployParameters = DeployParams { deployNodeName = deployNodeName } })
planTransactionActions :: [TransactionStage] -> [ProxmoxNetwork] -> [ProxmoxSDNZone] -> [ProxmoxSDNNetwork] -> Map Int ProxmoxVM -> TransactionState -> IO (Either TransactionException [TransactionAction])
planTransactionActions stages bridges sdnZones sdnNetworks vmMap state' = do
  (result, _) <- runStateT (runExceptT $ helper stages []) state'
  (return . fmap (sortOn transactionActionPriority)) result where
  helper :: [TransactionStage] -> [TransactionAction] -> StatefulTransactionM [TransactionAction]
  helper [] acc = (pure . reverse) acc
  helper ((NetworkExists (ExistingNetwork networkName)):ts) acc = if any ((==) networkName . proxmoxNetworkInterface) bridges then helper ts acc else
    throwE (BridgeNotFound networkName)
  helper ((NetworkExists SDNNetwork { .. }):ts) acc = do
    let sdnCreate = ProxmoxSDNNetworkCreate
          { sdnNetworkCreateZone=configNetworkZone
          , sdnNetworkCreateVlanaware=Nothing
          , sdnNetworkCreateTag=Nothing
          , sdnNetworkCreateName=configNetworkName
          , sdnNetworkCreateAlias=Nothing
          }
    if all ((/=) configNetworkZone . proxmoxSDNZoneName) sdnZones then throwE (SDNZoneNotFound configNetworkZone) else
      if any (\x -> sdnNetworkName x == configNetworkName && sdnNetworkZone x == configNetworkZone) sdnNetworks then
        helper ts acc
      else do
        let matchingNameNetwork = filter (\x -> sdnNetworkName x == configNetworkName && sdnNetworkZone x /= configNetworkZone) sdnNetworks
        case matchingNameNetwork of
          [] -> helper ts (defaultTransactionDelayAfter (DeploySDNNetwork sdnCreate):acc)
          ((ProxmoxSDNNetwork { sdnNetworkZone = conflictZone }):_) -> do
            helper ts (defaultTransactionDelayAfter (DeploySDNNetwork sdnCreate):defaultTransactionDelayAfter (DestroySDNNetwork (sdnCreate { sdnNetworkCreateZone = conflictZone })):acc)
  helper ((NetworkNotExists (ExistingNetwork {})):ts) acc = helper ts acc
  helper ((NetworkNotExists (SDNNetwork { .. })):ts) acc = do
    if any (\x -> sdnNetworkZone x == configNetworkZone && sdnNetworkName x == configNetworkName) sdnNetworks then do
      let sdnCreate = ProxmoxSDNNetworkCreate
           { sdnNetworkCreateZone = configNetworkZone
           , sdnNetworkCreateName = configNetworkName
           , sdnNetworkCreateVlanaware=Nothing
           , sdnNetworkCreateTag=Nothing
           , sdnNetworkCreateAlias=Nothing
           }
      helper ts (defaultTransactionDelayAfter (DestroySDNNetwork sdnCreate):acc)
    else helper ts acc
  helper ((TemplateExists t@(ConfigTemplate { configTemplateID = tID })):ts) acc = do
    case M.lookup tID vmMap of
      Nothing -> throwE (TemplateNotFound t)
      (Just (ProxmoxVM { vmTemplate=True, vmLock=Nothing })) -> helper ts acc
      _vmInvalid -> throwE (NonTemplateLink t)
  helper ((VMExists vm@(RawVM { configVMID = vmID, configVMName = vmName, configVMDelay = delay })):ts) acc = do
    case vmID of
      Nothing -> helper ts (TransactionDelayAfter delay (StartVM vmName):CreateVM vm:AssignVMID vmName:acc)
      (Just vmID') -> do
        case M.lookup vmID' vmMap of
          (Just _) -> helper ts acc -- TODO: reconfig VM (and unify vm check, wtf)
          Nothing -> do
            helper ts (TransactionDelayAfter delay (StartVM vmName):CreateVM vm:acc)
  helper ((VMExists (TemplatedConfigVM { configVMParentTemplate = parentTemplateName, configVMName = vmName, configVMID = vmID, configVMDelay = delay })):ts) acc = do
    (TransactionState { transactionDeployConfig = deployConfig@(DeployConfig { deployTemplates = vmTemplates, deployParameters = DeployParams { deployNodeName = deployNodeName } }), .. }) <- lift get
    data' <- transactionDataGetF
    case filter ((==) parentTemplateName . configTemplateName) vmTemplates of
      [] -> throwE (TemplateNotFound (ConfigTemplate {configTemplateName = parentTemplateName, configTemplateID = 0 }))
      (ConfigTemplate { configTemplateID = templateID }:_) -> do
        let cloneStage = CloneVM (ProxmoxVMCloneParams {proxmoxVMCloneVMID = templateID, proxmoxVMCloneStorage = Nothing, proxmoxVMCloneSnapname = Nothing, proxmoxVMCloneTarget = Just deployNodeName, proxmoxVMCloneNewID = fromMaybe (-1) vmID, proxmoxVMCloneName = (Just . T.pack) vmName, proxmoxVMCloneDescription=Nothing})
        case getVMID vmName data' deployConfig of
          Nothing -> helper ts (TransactionDelayAfter delay (StartVM vmName):cloneStage:AssignVMID vmName:acc)
          (Just vmID') -> do
            case M.lookup vmID' vmMap of
              (Just _) -> helper ts acc -- TODO: reconfig VM (and unify vm check, wtf)
              Nothing -> helper ts (TransactionDelayAfter delay (StartVM vmName):cloneStage:acc)
  helper ((NetworksRemoved vmName):ts) acc = helper ts (RemoveNetworks vmName:acc)
  helper ((NetworkConnected vmName networkConfig@(ConfigVMNetwork { .. })):ts) acc = do
    (TransactionState { transactionDeployConfig = deployConfig@(DeployConfig { deployNetworks = configNetworks, deployParameters = DeployParams { deployNodeName = deployNodeName }}),  ..}) <- lift get
    let networkNames = map configNetworkName configNetworks
    if configVMNetworkName `notElem` networkNames then throwE (NetworkIsNotDeclared $ configVMNetworkName) else do
      data' <- transactionDataGetF
      case getVMID vmName data' deployConfig of
        Nothing -> helper ts (AttachNetwork vmName networkConfig:acc)
        (Just vmID) -> do
          (ProxmoxResponse { proxmoxData = vmConfig'}) <- (liftIO . defaultRetryClient' transactionProxmoxState) (getVMConfig deployNodeName vmID) >>= defaultClientErrorWrapper
          case vmConfig' of
            Nothing -> helper ts (AttachNetwork vmName networkConfig:acc)
            (Just vmConfig) -> do
              let bridges = vmNetworkBridges vmConfig
              case configVMNetworkNumber of
                Nothing -> helper ts (AttachNetwork vmName networkConfig:acc)
                (Just vmNumber) -> do
                  case M.lookup vmNumber bridges of
                    Nothing -> helper ts (AttachNetwork vmName networkConfig:acc)
                    (Just bridgeName) -> if bridgeName == configVMNetworkName then
                      helper ts acc
                    else helper ts (AttachNetwork vmName networkConfig:acc)
  helper ((VMNotExists vm):ts) acc = do
    let vmName = configVMName vm
    helper ts (UnassignVMID vmName:DestroyVM vmName:StopVM vmName:acc)
