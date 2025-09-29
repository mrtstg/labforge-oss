{- Copyright (C) 2025 Ilya Zamaratskikh

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, see <http://www.gnu.org/licenses>. -}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
module Api.Handler (handleTask) where

import           Api.BaseUrl
import           Api.Deployment
import           Api.Keycloak.Models
import           Api.Keycloak.Models.User
import           Api.Keycloak.Token
import           Api.Keycloak.Utils
import           Auth.Client
import qualified Cluster.Client                           as Cluster
import           Cluster.Models.Node
import           Config
import           Control.Concurrent.STM
import           Control.Concurrent.STM.TQueue
import           Control.Monad.Except
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Control.Monad.State                      (runState, runStateT)
import qualified Data.ByteString.Char8                    as BS
import qualified Data.Map                                 as M
import           Data.Maybe
import           Data.Text                                (Text, pack, unpack)
import           Database
import           Database.Persist
import           Database.Persist.Postgresql
import           Deployment.Models.Deployment
import           Models
import qualified Proxmox.Client                           as P
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.Deploy
import           Proxmox.Deploy.Models.Config.DeployAgent
import           Proxmox.Deploy.Models.Config.Network
import           Proxmox.Deploy.Models.Config.Template
import           Proxmox.Deploy.Models.Config.VM
import           Proxmox.Deploy.Models.Transaction
import           Proxmox.Deploy.Ssl
import           Proxmox.Deploy.Transaction
import           Proxmox.Deploy.Types
import           Proxmox.Models
import           Proxmox.Models.Network
import           Proxmox.Models.Snapshot
import           Proxmox.Models.Storage
import           Proxmox.Retry
import           Proxmox.Schema
import           Servant.Client
import           Service.Environment
import           Utils

allocateDisplays :: Text -> DeploymentInstanceDataId -> Int -> [Int] -> AppT (Maybe [Int])
allocateDisplays node dId amount = helper [] where
  helper :: [Int] -> [Int] -> AppT (Maybe [Int])
  helper acc [] | length acc == amount = (pure . pure) acc
                | otherwise = pure Nothing
  helper acc (n:ns) | length acc == amount = (pure . pure) acc
                    | otherwise = do
    displayHold <- runDB $ exists [ UsedDisplayNum ==. n, UsedDisplayNodeName ==. node ]
    if displayHold then helper acc ns else do
      _ <- runDB $ insert (UsedDisplay {usedDisplayUsedBy=dId, usedDisplayNum=n, usedDisplayNodeName=node})
      helper (n:acc) ns

-- TODO: what if network allocated on its deployment?
-- logic: get all instances from db and request lacked amount
allocateNetworks :: DeploymentInstanceDataId -> Int -> [String] -> AppT (Maybe [String])
allocateNetworks dId amount pool = do
  helper [] pool where
    helper :: [String] -> [String] -> AppT (Maybe [String])
    helper acc [] | length acc == amount = (pure . pure) acc
                  | otherwise = pure Nothing
    helper acc (n:ns) | length acc == amount = (pure . pure) acc
                      | otherwise = do
      nameHold <- runDB $ exists [ UsedBridgesName ==. pack n ]
      if nameHold then helper acc ns else do
        _ <- runDB $ insert (UsedBridges {usedBridgesUsedBy=dId, usedBridgesName=pack n})
        helper (n:acc) ns

allocateVMID :: DeploymentInstanceDataId -> Int -> [Int] -> AppT (Maybe [Int])
allocateVMID dId amount = helper [] where
  helper :: [Int] -> [Int] -> AppT (Maybe [Int])
  helper acc [] | length acc /= amount = pure Nothing
                | otherwise = pure $ Just acc
  helper acc (n:ns) | length acc /= amount = do
    idHold <- runDB $ exists [ UsedVMIDNum ==. n ]
    if idHold then helper acc ns else do
      _ <- runDB $ insert (UsedVMID {usedVMIDUsedBy=dId, usedVMIDNum=n})
      helper (n:acc) ns
                    | otherwise = (pure . pure) acc

getTakenVMID :: ProxmoxState -> AppT (Either String [Int])
getTakenVMID state = do
  vmMap <- defaultRetryClient' state P.getActiveNodeVMNodeMap
  case vmMap of
    (Left e) -> do
      $(logError) $ "Failed to get nodes: " <> (pack . show) e
      (return . Left . show) e
    (Right vms) -> (pure . pure) (map fst $ M.toList vms)

addLogToDeploymentInstance :: Key DeploymentInstanceData -> Text -> AppT ()
addLogToDeploymentInstance dID msg = do
  actualInstance <- runDB $ get dID
  case actualInstance of
    Nothing -> pure ()
    (Just (DeploymentInstanceData { deploymentInstanceDataLogs = oldLogs })) -> do
      runDB $ updateWhere [ DeploymentInstanceDataId ==. dID ] [ DeploymentInstanceDataLogs =. oldLogs ++ [msg] ]

setDeploymentInstanceStatus :: Key DeploymentInstanceData -> DeploymentStatus -> AppT ()
setDeploymentInstanceStatus dID status = do
  runDB $ updateWhere [ DeploymentInstanceDataId ==. dID ] [ DeploymentInstanceDataState =. status ]

deployTransaction :: [TransactionStage] -> DeploymentInstanceDataId -> DeployConfig -> AppT Bool
deployTransaction stages deploymentKey deployConfig@(DeployConfig { deployParameters = DeployParams {deployUrl=deployUrl, deployNodeName=nodeName} }) = do
  cfg <- ask
  parseRes <- liftIO $ tryParseUrl (unpack deployUrl)
  case parseRes of
    (Left e) -> do
      $(logError) $ "Failed to parse URL: " <> pack e
      addLogToDeploymentInstance deploymentKey $ "Failed to parse URL: " <> pack e
      --setDeploymentInstanceStatus deploymentKey Failed
      pure False
    (Right url) -> do
      m <- liftIO $ createProxmoxManager deployConfig
      let state = ProxmoxState url m
      let planState = TransactionState { transactionTarget=Deploy
        , transactionProxmoxState=state
        , transactionLogFunction=instanceLogFunction cfg deploymentKey
        , transactionDeployConfig=deployConfig
        , transactionDataSetF=(\_ -> pure ())
        , transactionDataGetF=pure (TransactionData M.empty)
        , transactionAllocateVMIDF=throwError (UnknownError "Cant allocate VMID")
        , transactionActions=[]
        }
      v <- liftIO $ runProxmoxClient' state $ do
        a <- P.getBridgeNodeNetworks nodeName
        (ProxmoxResponse b _) <- P.getSDNZones
        (ProxmoxResponse c _) <- P.getSDNNetworks
        d <- P.getNodeStorage nodeName defaultProxmoxStorageFilter
        e <- P.getActiveNodesVMMap
        pure (a, b, c, d, e)
      case v of
        (Left e) -> do
          $(logError) $ "Failed to get PVE data: " <> (pack . show) e
          addLogToDeploymentInstance deploymentKey $ "Failed to get PVE data: " <> (pack . show) e
          --setDeploymentInstanceStatus deploymentKey Failed
          pure False
        (Right (a, b, c, d, e)) -> do
          planRes <- liftIO $ planTransactionActions stages a b c d e planState
          case planRes of
            (Left e) -> do
              $(logError) $ "Failed to plan transaction: " <> (pack . show) e
              addLogToDeploymentInstance deploymentKey $ "Failed to plan transaction: " <> (pack . show) e
              --setDeploymentInstanceStatus deploymentKey Failed
              pure False
            (Right actions) -> do
              result <- (liftIO . runExceptT) $ (runStateT (unTransaction executeTransaction) (planState { transactionActions = actions }))
              case result of
                (Left e) -> do
                  $(logError) $ "Failed to run transaction: " <> (pack . show) e
                  addLogToDeploymentInstance deploymentKey $ "Failed to run transaction: " <> (pack . show) e
                  --setDeploymentInstanceStatus deploymentKey Failed
                  pure False
                (Right _) -> do
                  --setDeploymentInstanceStatus deploymentKey (if target == Deploy then Deployed else Created)
                  pure True

generateAndDeployTransaction :: DeployTarget -> DeploymentInstanceDataId -> DeployConfig -> AppT Bool
generateAndDeployTransaction target deploymentKey deployConfig@(DeployConfig { deployParameters = DeployParams {deployUrl=deployUrl, deployNodeName=nodeName} }) = do
  cfg <- ask
  parseRes <- liftIO $ tryParseUrl (unpack deployUrl)
  case parseRes of
    (Left e) -> do
      $(logError) $ "Failed to parse URL: " <> pack e
      addLogToDeploymentInstance deploymentKey $ "Failed to parse URL: " <> pack e
      setDeploymentInstanceStatus deploymentKey Failed
      pure False
    (Right url) -> do
      m <- liftIO $ createProxmoxManager deployConfig
      let stages = planTransactionStages deployConfig target
      let state = ProxmoxState url m
      let planState = TransactionState { transactionTarget=target
        , transactionProxmoxState=state
        , transactionLogFunction=instanceLogFunction cfg deploymentKey
        , transactionDeployConfig=deployConfig
        , transactionDataSetF=(\_ -> pure ())
        , transactionDataGetF=pure (TransactionData M.empty)
        , transactionAllocateVMIDF=throwError (UnknownError "Cant allocate VMID")
        , transactionActions=[]
        }
      v <- liftIO $ runProxmoxClient' state $ do
        a <- P.getBridgeNodeNetworks nodeName
        (ProxmoxResponse b _) <- P.getSDNZones
        (ProxmoxResponse c _) <- P.getSDNNetworks
        d <- P.getNodeStorage nodeName defaultProxmoxStorageFilter
        e <- P.getActiveNodesVMMap
        pure (a, b, c, d, e)
      case v of
        (Left e) -> do
          $(logError) $ "Failed to get PVE data: " <> (pack . show) e
          addLogToDeploymentInstance deploymentKey $ "Failed to get PVE data: " <> (pack . show) e
          setDeploymentInstanceStatus deploymentKey Failed
          pure False
        (Right (a, b, c, d, e)) -> do
          planRes <- liftIO $ planTransactionActions stages a b c d e planState
          case planRes of
            (Left e) -> do
              $(logError) $ "Failed to plan transaction: " <> (pack . show) e
              addLogToDeploymentInstance deploymentKey $ "Failed to plan transaction: " <> (pack . show) e
              setDeploymentInstanceStatus deploymentKey Failed
              pure False
            (Right actions) -> do
              result <- (liftIO . runExceptT) $ (runStateT (unTransaction executeTransaction) (planState { transactionActions = actions }))
              case result of
                (Left e) -> do
                  $(logError) $ "Failed to run transaction: " <> (pack . show) e
                  addLogToDeploymentInstance deploymentKey $ "Failed to run transaction: " <> (pack . show) e
                  setDeploymentInstanceStatus deploymentKey Failed
                  pure False
                (Right _) -> do
                  setDeploymentInstanceStatus deploymentKey (if target == Deploy then Deployed else Created)
                  pure True

handleTask :: TQueue QueryRequest -> QueryRequest -> AppT ()
handleTask taskQuery (AllocateNode dID) = do
  let instanceKey = (DeploymentInstanceDataKey dID)
  let logInstance = addLogToDeploymentInstance instanceKey
  let setStatus = setDeploymentInstanceStatus instanceKey

  $(logDebug) $ "Got AllocateNode request for " <> dID
  deployment <- runDB $ get instanceKey
  case deployment of
    Nothing -> $(logError) $ "Failed to find deployment with ID " <> dID
    (Just inst@(DeploymentInstanceData { .. })) -> do
      authEnv <- asks $ getEnvFor AuthService
      ownerData'' <- withTokenVariable $ \t -> do
        defaultRetryClientC authEnv $ getUserBriefInfo deploymentInstanceDataOwnerId (BearerWrapper t)
      case ownerData'' of
        (Left e) -> do
          logInstance $ "Failed to allocate token: " <> pack e
          setStatus Failed
        (Right (Left e)) -> do
          logInstance $ "Error response from auth: " <> (pack . show) e
          setStatus Failed
        (Right (Right (BriefUser { .. }))) -> do
          logInstance "Allocating deploy node"
          ~(Just (DeploymentTemplateData { .. })) <- runDB $ get deploymentInstanceDataParent
          let vmTags = map unpack [deploymentTemplateDataTitle, fromMaybe "" userFirstName <> " " <> fromMaybe "" userLastName]
          clusterEnv <- asks $ getEnvFor ClusterManager
          nodeRequest <- withTokenVariable' $ \t -> do
            runClientApp clusterEnv $ Cluster.getDeployNode (BearerWrapper t)
          case nodeRequest of
            (Left e) -> do
              $(logError) $ "Error response from cluster manager: " <> (pack . show) e
              logInstance $ "Cluster manager error: " <> (pack . show) e
              setStatus Failed
            (Right (ClusterNode { .. })) -> do
              logInstance "Allocated node"
              let deployNode = DeployParams { deployUrl = nodeApiUrl
                , deployToken = Just nodeApiToken
                , deployStartVMID = fromMaybe 100 nodeStartVMID
                , deployNodeName = nodeName
                , deployIgnoreSSL = nodeIgnoreSSL
                }
              let agentConfig = DeployAgentConfig { configAgentURL = nodeAgentUrl
                , configAgentToken = nodeAgentToken
                , configAgentDisplayNetwork = nodeDisplayNetwork
                }
              pveUrl' <- liftIO $ tryParseUrl (unpack nodeApiUrl)
              case pveUrl' of
                (Left e) -> do
                  $(logError) $ "Failed to parse base URL: " <> pack e
                  logInstance $ "Failed to base node URL: " <> pack e
                  setStatus Failed
                (Right pveUrl) -> do
                  mgr <- liftIO $ createProxmoxManager (DeployConfig { deployParameters = deployNode, deployTemplates = [], deployNetworks = [], deployVMs = [], deployAgent = Nothing })
                  let state = ProxmoxState pveUrl mgr
                  ~(Right takenIds) <- getTakenVMID state
                  allocRes <- allocateVMID instanceKey (length deploymentTemplateDataVms) (filter (`notElem` takenIds) [fromMaybe 100 nodeStartVMID..9999999])
                  case allocRes of
                    Nothing -> do
                      $(logError) $ "Failed to allocate VMIDs!"
                      logInstance $ "Failed to allocate VMID"
                      setStatus Failed
                    (Just vmid) -> do
                      sdnZone <- asks (unpack . deploySDNZone)
                      let sdnNetworksNames = filter (`notElem` deploymentTemplateDataExistingNetworks) $ map (pack . configVMNetworkName) $ foldMap (fromMaybe [] . configVMNetworks) deploymentTemplateDataVms
                      nodeBridges' <- defaultRetryClient' state $ P.getBridgeNodeNetworks nodeName
                      case nodeBridges' of
                        (Left e) -> do
                          $(logError) $ "Failed to get node bridges: " <> (pack . show) e
                          logInstance $ "Failed to get node bridges: " <> (pack . show) e
                          setStatus Failed
                        (Right nodeBridges) -> do
                          let bridgesNames = map proxmoxNetworkInterface nodeBridges
                          let sdnNamesPool = filter (`notElem` bridgesNames) $ iterLetters 8
                          sdnAllocRes <- allocateNetworks instanceKey (length sdnNetworksNames) sdnNamesPool
                          case sdnAllocRes of
                            Nothing -> do
                              $(logError) $ "Failed to allocate nets!"
                              logInstance $ "Failed to allocate networks"
                              setStatus Failed
                            (Just sdnNames) -> do
                              let namesMap = M.mapKeys unpack . M.fromList $ zip sdnNetworksNames sdnNames
                              let networks = map (ExistingNetwork . unpack) deploymentTemplateDataExistingNetworks ++ map (\n -> SDNNetwork {configNetworkZone=sdnZone, configNetworkVLANAware=Nothing, configNetworkSubnets=[], configNetworkName=n}) sdnNames
                              let replacedNetworksVM = map (renameNet namesMap) deploymentTemplateDataVms
                              displayAllocRes <- allocateDisplays nodeName instanceKey (length deploymentTemplateDataVms) [x | x <- [nodeMinDisplay..nodeMaxDisplay], 5900 + x `notElem` nodeExcludedPorts]
                              case displayAllocRes of
                                Nothing -> do
                                  $(logError) $ "Failed to allocate displays!"
                                  logInstance $ "Failed to allocate displays"
                                  setStatus Failed
                                (Just vmDisplays) -> do
                                  let zippedDisplays = zip replacedNetworksVM vmDisplays
                                  let linksMap = M.mapKeys configVMName $ M.map (\d -> unpack nodeName <> "-" <> show d) $ M.fromList zippedDisplays
                                  let configuredVMs = zipWith (\d v -> v {configVMID = Just d, configVMTags = vmTags}) vmid (map (\ (v, d) -> v {configVMDisplay = Just d}) zippedDisplays)
                                  templates <- runDB $ selectList [ MachineTemplateDataName <-. map (pack . configVMParentTemplate) configuredVMs ] []
                                  let deployConfig = DeployConfig { deployAgent=Just agentConfig
                                    , deployVMs=configuredVMs
                                    , deployNetworks=networks
                                    , deployTemplates=map (\e -> ConfigTemplate {configTemplateName=(unpack . machineTemplateDataName . entityVal) e, configTemplateID=(fromIntegral . fromSqlKey . entityKey) e}) templates
                                    , deployParameters=deployNode
                                    }
                                  runDB $ updateWhere [ DeploymentInstanceDataId ==. instanceKey ]
                                    [ DeploymentInstanceDataDeployConfig =. Just deployConfig
                                    , DeploymentInstanceDataNetworkNamesMap =. namesMap
                                    , DeploymentInstanceDataVmLinks =. linksMap
                                    ]
                                  (liftIO . atomically) $ writeTQueue taskQuery (DeployInstance dID)
handleTask taskQuery (GroupDeployment tID groupName) = do
  $(logDebug) $ "Creating group deployment for " <> groupName <> "(" <> (pack . show) tID <> ")"
  authEnv <- asks $ getEnvFor AuthService
  groupMembersResp <- withTokenVariable' $ \t -> runClientApp authEnv $ getAllGroupMembers groupName (BearerWrapper t)
  case groupMembersResp of
    (Left e) -> $(logError) $ "Group members request error: " <> (pack . show) e
    (Right users) -> do
      let usersId = map userID users
      existingDeployments <- runDB $ selectKeysList [
        DeploymentInstanceDataOwnerId <-. usersId,
        DeploymentInstanceDataParent ==. DeploymentTemplateDataKey (fromIntegral tID),
        DeploymentInstanceDataState ==. Created,
        DeploymentInstanceDataDeployConfig !=. Nothing
        ] []
      mapM_ (\(DeploymentInstanceDataKey t) -> (liftIO . atomically) $ writeTQueue taskQuery (DeployInstance t)) existingDeployments
      newDeployments <- createMissingDeployments (DeploymentTemplateDataKey $ fromIntegral tID) tID users
      mapM_ (\t -> (liftIO . atomically) $ writeTQueue taskQuery (AllocateNode t)) newDeployments
handleTask taskQuery (GroupDestroy tID groupName) = do
  $(logDebug) $ "Creating group destroy for " <> groupName <> "(" <> (pack . show) tID <> ")"
  authEnv <- asks $ getEnvFor AuthService
  groupMembersResp <- withTokenVariable' $ \t -> runClientApp authEnv $ getAllGroupMembers groupName (BearerWrapper t)
  case groupMembersResp of
    (Left e) -> $(logError) $ "Group members request error: " <> (pack . show) e
    (Right users) -> do
      let usersId = map userID users
      existingDeployments <- runDB $ selectKeysList [
        DeploymentInstanceDataOwnerId <-. usersId,
        DeploymentInstanceDataParent ==. DeploymentTemplateDataKey (fromIntegral tID),
        DeploymentInstanceDataState !=. Created,
        DeploymentInstanceDataState !=. Destroying,
        DeploymentInstanceDataState !=. Deploying,
        DeploymentInstanceDataDeployConfig !=. Nothing
        ] []
      mapM_ (\(DeploymentInstanceDataKey t) -> (liftIO . atomically) $ writeTQueue taskQuery (DestroyInstance t)) existingDeployments
handleTask taskQuery (GroupRollback tID groupName snapName) = do
  $(logDebug) $ "Creating group rollback for " <> groupName <> "(" <> (pack . show) tID <> ")"
  authEnv <- asks $ getEnvFor AuthService
  groupMembersResp <- withTokenVariable' $ \t -> runClientApp authEnv $ getAllGroupMembers groupName (BearerWrapper t)
  case groupMembersResp of
    (Left e) -> $(logError) $ "Group members request error: " <> (pack . show) e
    (Right users) -> do
      let usersId = map userID users
      existingDeployments <- runDB $ selectKeysList [
        DeploymentInstanceDataOwnerId <-. usersId,
        DeploymentInstanceDataParent ==. DeploymentTemplateDataKey (fromIntegral tID),
        DeploymentInstanceDataState ==. Deployed,
        DeploymentInstanceDataDeployConfig !=. Nothing
        ] []
      mapM_ (\(DeploymentInstanceDataKey t) -> (liftIO . atomically) $ writeTQueue taskQuery (RollbackInstance t snapName)) existingDeployments
handleTask taskQuery (DeploymentMakeSnapshot dID snapName) = do
  let instanceKey = (DeploymentInstanceDataKey dID)
  let logInstance = addLogToDeploymentInstance instanceKey
  let setStatus = setDeploymentInstanceStatus instanceKey
  $(logInfo) $ "Snapping instance " <> (pack . show) dID
  instance' <- runDB $ get (DeploymentInstanceDataKey dID)
  case instance' of
    Nothing -> $(logError) $ "Deploy instance " <> dID <> " not found"
    (Just (DeploymentInstanceData { .. })) -> do
      case deploymentInstanceDataDeployConfig of
        Nothing -> do
          $(logError) $ "Deployment config is not set!"
          logInstance "Deployment config is not set!"
          setStatus Failed
        (Just deployConfig@(DeployConfig { deployVMs = vms })) -> do
          _ <- deployTransaction (map (`SnapshotExists` (ProxmoxSnapshotCreate {snapshotCreateStateful=Just True, snapshotCreateName=snapName, snapshotCreateDesc=Nothing})) vms) instanceKey deployConfig
          pure ()
handleTask taskQuery (DeploymentDeleteSnapshot dID snapName) = do
  let instanceKey = (DeploymentInstanceDataKey dID)
  let logInstance = addLogToDeploymentInstance instanceKey
  let setStatus = setDeploymentInstanceStatus instanceKey
  $(logInfo) $ "Removing snapshot of instance " <> (pack . show) dID
  instance' <- runDB $ get (DeploymentInstanceDataKey dID)
  case instance' of
    Nothing -> $(logError) $ "Deploy instance " <> dID <> " not found"
    (Just (DeploymentInstanceData { .. })) -> do
      case deploymentInstanceDataDeployConfig of
        Nothing -> do
          $(logError) $ "Deployment config is not set!"
          logInstance "Deployment config is not set!"
          setStatus Failed
        (Just deployConfig@(DeployConfig { deployVMs = vms })) -> do
          _ <- deployTransaction (map (`SnapshotNotExists` (ProxmoxSnapshotCreate {snapshotCreateStateful=Just True, snapshotCreateName=snapName, snapshotCreateDesc=Nothing})) vms) instanceKey deployConfig
          pure ()
handleTask taskQuery (RollbackInstance dID snapName) = do
  let instanceKey = (DeploymentInstanceDataKey dID)
  let logInstance = addLogToDeploymentInstance instanceKey
  let setStatus = setDeploymentInstanceStatus instanceKey
  $(logInfo) $ "Rollback of instance " <> (pack . show) dID
  instance' <- runDB $ get (DeploymentInstanceDataKey dID)
  case instance' of
    Nothing -> $(logError) $ "Deploy instance " <> dID <> " not found"
    (Just (DeploymentInstanceData { .. })) -> do
      case deploymentInstanceDataDeployConfig of
        Nothing -> do
          $(logError) $ "Deployment config is not set!"
          logInstance "Deployment config is not set!"
          setStatus Failed
        (Just deployConfig@(DeployConfig { deployVMs = vms })) -> do
          _ <- deployTransaction (map (`VMRollbacked` unpack snapName) vms) instanceKey deployConfig
          pure ()
handleTask taskQuery (DeployInstance dID) = do
  let instanceKey = (DeploymentInstanceDataKey dID)
  let logInstance = addLogToDeploymentInstance instanceKey
  let setStatus = setDeploymentInstanceStatus instanceKey

  $(logInfo) $ "Deploying instance " <> (pack . show) dID
  instance' <- runDB $ get (DeploymentInstanceDataKey dID)
  case instance' of
    Nothing -> $(logError) $ "Deploy instance " <> dID <> " not found"
    (Just (DeploymentInstanceData { .. })) -> do
      setStatus Deploying
      case deploymentInstanceDataDeployConfig of
        Nothing -> do
          $(logError) $ "Deployment config is not set!"
          logInstance "Deployment config is not set!"
          setStatus Failed
        (Just deployConfig) -> do
          _ <- generateAndDeployTransaction Deploy instanceKey deployConfig
          pure ()
handleTask tasksQueue (DestroyInstance dID) = do
  let instanceKey = (DeploymentInstanceDataKey dID)
  let logInstance = addLogToDeploymentInstance instanceKey
  let setStatus = setDeploymentInstanceStatus instanceKey

  $(logInfo) $ "Destroying instance " <> (pack . show) dID
  instance' <- runDB $ get (DeploymentInstanceDataKey dID)
  case instance' of
    Nothing -> $(logError) $ "Deploy instance " <> dID <> " not found"
    (Just (DeploymentInstanceData { .. })) -> do
      setStatus Destroying
      case deploymentInstanceDataDeployConfig of
        Nothing -> do
          $(logError) $ "Deployment config is not set!"
          logInstance "Deployment config is not set!"
          setStatus Created
        (Just deployConfig) -> do
          deployed <- generateAndDeployTransaction Destroy instanceKey deployConfig
          if deployed then runDB $ delete instanceKey else pure ()
handleTask taskQuery (GroupMakeSnapshot tID groupName snapName) = do
  authEnv <- asks $ getEnvFor AuthService
  groupMembersResp <- withTokenVariable' $ \t -> runClientApp authEnv $ getAllGroupMembers groupName (BearerWrapper t)
  case groupMembersResp of
    (Left e) -> $(logError) $ "Group members request error: " <> (pack . show) e
    (Right users) -> do
      let usersId = map userID users
      existingDeployments <- runDB $ selectKeysList [
        DeploymentInstanceDataOwnerId <-. usersId,
        DeploymentInstanceDataParent ==. DeploymentTemplateDataKey (fromIntegral tID),
        DeploymentInstanceDataState ==. Deployed,
        DeploymentInstanceDataDeployConfig !=. Nothing
        ] []
      mapM_ (\(DeploymentInstanceDataKey t) -> (liftIO . atomically) $ writeTQueue taskQuery (DeploymentMakeSnapshot t snapName)) existingDeployments
handleTask taskQuery (GroupDeleteSnapshot tID groupName snapName) = do
  authEnv <- asks $ getEnvFor AuthService
  groupMembersResp <- withTokenVariable' $ \t -> runClientApp authEnv $ getAllGroupMembers groupName (BearerWrapper t)
  case groupMembersResp of
    (Left e) -> $(logError) $ "Group members request error: " <> (pack . show) e
    (Right users) -> do
      let usersId = map userID users
      existingDeployments <- runDB $ selectKeysList [
        DeploymentInstanceDataOwnerId <-. usersId,
        DeploymentInstanceDataParent ==. DeploymentTemplateDataKey (fromIntegral tID),
        DeploymentInstanceDataState ==. Deployed,
        DeploymentInstanceDataDeployConfig !=. Nothing
        ] []
      mapM_ (\(DeploymentInstanceDataKey t) -> (liftIO . atomically) $ writeTQueue taskQuery (DeploymentDeleteSnapshot t snapName)) existingDeployments
handleTask _ (GroupPower tID groupName powerOn) = do
  authEnv <- asks $ getEnvFor AuthService
  groupMembersResp <- withTokenVariable' $ \t -> runClientApp authEnv $ getAllGroupMembers groupName (BearerWrapper t)
  case groupMembersResp of
    (Left e) -> $(logError) $ "Group members request error: " <> (pack . show) e
    (Right users) -> do
      let usersId = map userID users
      existingDeployments <- runDB $ selectList [
        DeploymentInstanceDataOwnerId <-. usersId,
        DeploymentInstanceDataParent ==. DeploymentTemplateDataKey (fromIntegral tID),
        DeploymentInstanceDataState !=. Created,
        DeploymentInstanceDataState !=. Destroying,
        DeploymentInstanceDataState !=. Deploying,
        DeploymentInstanceDataDeployConfig !=. Nothing
        ] []
      let f = if powerOn then P.startVM else P.stopVM
      forM_ existingDeployments $ \(Entity dID DeploymentInstanceData { .. }) -> do
        $(logInfo) $ "Entering deployment " <> (pack . show) dID
        case deploymentInstanceDataDeployConfig of
          Nothing -> pure ()
          (Just deployConfig@(DeployConfig { deployParameters = DeployParams { .. }, .. })) -> do
            mgr <- liftIO $ createProxmoxManager deployConfig
            url <- liftIO $ parseBaseUrl (unpack deployUrl)
            let state = ProxmoxState url mgr
            forM_ deployVMs $ \vm -> do
              let vmId = fromMaybe (-1) $ configVMID vm
              _ <- defaultRetryClient' state (f deployNodeName vmId)
              $(logInfo) $ "Turned " <> (if powerOn then "on " else "off ") <> (pack . show) vmId
handleTask _ r = do
  $(logInfo) $ (pack . show) r
  pure ()

instanceLogFunction :: Config -> Key DeploymentInstanceData -> Loc -> LogSource -> LogLevel -> LogStr -> IO ()
instanceLogFunction config dID loc src level msg = (appTIO (f dID loc src level msg) config) >> pure () where
  f :: Key DeploymentInstanceData -> Loc -> LogSource -> LogLevel -> LogStr -> AppT ()
  f dID loc src level str = do
    let m = fromLogStr (defaultLogStr loc src level str)
    addLogToDeploymentInstance dID (pack . BS.unpack $ m)
    pure ()

createMissingDeployments :: Key DeploymentTemplateData -> Int -> [BriefUser] -> AppT [Text]
createMissingDeployments tID tIDnum = helper [] where
  helper :: [Text] -> [BriefUser] -> AppT [Text]
  helper acc [] = pure acc
  helper acc (BriefUser { .. }:users) = do
    let key = userID <> "-" <> (pack . show) tIDnum
    instanceExists <- runDB $ exists [ DeploymentInstanceDataId ==. DeploymentInstanceDataKey key ]
    if instanceExists then helper acc users else do
      let instanceEntity = DeploymentInstanceData { deploymentInstanceDataVmLinks=M.empty
        , deploymentInstanceDataState=Created
        , deploymentInstanceDataParent=tID
        , deploymentInstanceDataOwnerId=userID
        , deploymentInstanceDataNetworkNamesMap=M.empty
        , deploymentInstanceDataLogs=[]
        , deploymentInstanceDataDeployConfig=Nothing
        }
      _ <- runDB $ insertKey (DeploymentInstanceDataKey key) instanceEntity
      helper (key:acc) users

renameNet :: M.Map String String -> ConfigVM -> ConfigVM
renameNet _ vmData@(TemplatedConfigVM { configVMNetworks = Nothing }) = vmData
renameNet namesMap vmData@(TemplatedConfigVM { configVMNetworks = Just nets }) = vmData { configVMNetworks = Just (map f nets) } where
  f :: ConfigVMNetwork -> ConfigVMNetwork
  f d@(ConfigVMNetwork { configVMNetworkName = n }) = case M.lookup n namesMap of
    Nothing  -> d
    (Just v) -> d { configVMNetworkName = v }
