{- Copyright (C) 2025 Ilya Zamaratskikh

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License:<|> or
(at your option) any later version.

This program is distributed in the hope that it will be useful:<|>
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not:<|> see <http://www.gnu.org/licenses>. -}
{-# LANGUAGE DataKinds          #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE RecordWildCards    #-}
{-# LANGUAGE TemplateHaskell    #-}
{-# LANGUAGE TypeOperators      #-}
module Api.Deployment
  ( deploymentServer
  , deploymentInstanceKey
  ) where

import           Api
import           Api.BaseUrl
import           Api.Keycloak.Models
import           Api.Keycloak.Models.Introspect
import           Api.Keycloak.Models.User
import           Api.Keycloak.Utils
import           Api.Retry
import           Auth
import           Auth.Client
import           Auth.Token
import           Cluster.Client
import           Cluster.Models.Node
import           Config
import           Control.Concurrent                       (threadDelay)
import           Control.Monad                            (unless, when)
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import           Data.Either                              (fromRight, isLeft)
import           Data.Functor                             ((<&>))
import           Data.List                                (find, sortOn)
import qualified Data.Map                                 as M
import           Data.Maybe
import           Data.Ord                                 (Down (..))
import           Data.Text                                (Text)
import qualified Data.Text                                as T
import           Database
import           Database.Persist
import           Database.Persist.Postgresql
import           Deployment.Models.Deployment
import           Deployment.Models.Stats
import           Deployment.Schema
import           Jobservice.Client
import qualified Jobservice.Client                        as J
import           Jobservice.Models
import           Models
import           Models.JSONError
import           Network.HTTP.Types
import           Pool
import qualified Proxmox.Client                           as P
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.Deploy
import           Proxmox.Deploy.Models.Config.DeployAgent
import           Proxmox.Deploy.Models.Config.Network
import           Proxmox.Deploy.Models.Config.Template
import           Proxmox.Deploy.Models.Config.VM
import           Proxmox.Deploy.Ssl
import           Proxmox.Models
import           Proxmox.Models.Network
import           Proxmox.Models.Snapshot
import           Proxmox.Models.VM
import           Proxmox.Models.VMConfig
import           Proxmox.Retry                            (defaultRetryClient',
                                                           defaultRetryClientC')
import           Proxmox.Schema
import           Redis.Common
import           Redis.Lock
import           Servant
import           Servant.Client
import           Service.Environment
import           System.Random
import           Utils
import           Utils.Time

templateAdminRole = "image-admin"
templateReadRole = "image-view"
pageSize = 20

data DeploymentOwnership = TemplateOwner | DeploymentOwner | NotOwner deriving (Show, Eq)

isDeploymentOwner :: IntrospectResponse -> DeploymentInstanceDataId -> AppT DeploymentOwnership
isDeploymentOwner InactiveToken _ = pure NotOwner
isDeploymentOwner token@ActiveToken { .. } deploymentId = do
  v <- runDB $ get deploymentId
  case v of
    Nothing -> pure NotOwner
    (Just (DeploymentInstanceData { .. })) -> do
      isOwner <- isDeploymentTemplateOwner token deploymentInstanceDataParent
      pure $ if isOwner then TemplateOwner else if tokenUUID == Just deploymentInstanceDataOwnerId then DeploymentOwner else NotOwner

isDeploymentTemplateOwner :: IntrospectResponse -> DeploymentTemplateDataId -> AppT Bool
isDeploymentTemplateOwner InactiveToken _      = pure False
isDeploymentTemplateOwner ActiveToken { .. } templateId = do
  v <- runDB $ get templateId
  case v of
    Nothing -> pure False
    (Just (DeploymentTemplateData { .. })) -> do
      pure $ deployTemplatesAdmin `elem` tokenRealmRoles || tokenUUID == Just deploymentTemplateDataOwnerId

isDeploymentTemplateAdministrator :: IntrospectResponse -> DeploymentTemplateDataId -> AppT Bool
isDeploymentTemplateAdministrator InactiveToken _ = pure False
isDeploymentTemplateAdministrator token templateId   = isDeploymentTemplateOwner token templateId

isDeploymentTemplateOperator :: IntrospectResponse -> DeploymentTemplateDataId -> AppT Bool
isDeploymentTemplateOperator InactiveToken _            = pure False
isDeploymentTemplateOperator token@ActiveToken { .. } templateId = isDeploymentTemplateOwner token templateId

getTemplateNameList :: [Text] -> BearerWrapper -> AppT [ConfigTemplate]
getTemplateNameList names (BearerWrapper token) = do
  _ <- requireManyRealmRoles token [[templateAdminRole], [templateReadRole]]
  templates <- runDB $ selectList [MachineTemplateDataName <-. names] []
  return $ map (\(Entity k (MachineTemplateData { .. })) -> ConfigTemplate {configTemplateID=(fromIntegral . fromSqlKey) k, configTemplateName=T.unpack machineTemplateDataName}) templates

getPagedTemplates :: Maybe Int -> BearerWrapper -> AppT (PagedResponse [ConfigTemplate])
getPagedTemplates pageN (BearerWrapper token) = do
  _ <- requireManyRealmRoles token [[templateAdminRole], [templateReadRole]]
  let page = max 1 $ fromMaybe 1 pageN
  totalTemplates <- runDB $ count ([] :: [Filter MachineTemplateData])
  tmpls <- runDB $ selectList ([] :: [Filter MachineTemplateData]) [OffsetBy (pageSize * (page - 1)), LimitTo pageSize]
  pure $ PagedResponse
    { responseTotal=totalTemplates
    , responsePageSize=pageSize
    , responseObjects=map (\e -> ConfigTemplate {configTemplateName=(T.unpack . machineTemplateDataName . entityVal) e, configTemplateID=(fromIntegral . fromSqlKey . entityKey) e}) tmpls
    }

deleteTemplate :: Int -> BearerWrapper -> AppT ()
deleteTemplate templateID (BearerWrapper token) = do
  _ <- requireRealmRoles token [templateAdminRole]
  template' <- runDB $ get (MachineTemplateDataKey . fromIntegral $ templateID)
  case template' of
    Nothing -> sendJSONError err404 (JSONError "notFound" "Template not found" Null)
    (Just (MachineTemplateData templateName)) -> do
      jobEnv <- asks $ getEnvFor JobserviceAPI
      images <- withTokenVariable'' $ \t -> defaultRetryClientC jobEnv (getHeldImages (BearerWrapper t))
      if T.unpack templateName `elem` images then do
        sendJSONError err400 (JSONError "imageHeld" "This image is held by deployments" Null)
      else do
        _ <- runDB $ deleteWhere [ MachineTemplateDataId ==. (toSqlKey . fromIntegral) templateID ]
        pure ()

createTemplate :: ConfigTemplate -> BearerWrapper -> AppT ()
createTemplate (ConfigTemplate { .. }) (BearerWrapper token) = do
  _ <- requireRealmRoles token [templateAdminRole]
  paramsTaken <- runDB $ exists ([MachineTemplateDataId ==. (toSqlKey . fromIntegral) configTemplateID] ||. [MachineTemplateDataName ==. T.pack configTemplateName])
  if paramsTaken then sendJSONError err400 (JSONError "badRequest" "Template name or ID is taken" Null) else do
    _ <- runDB $ insertKey ((MachineTemplateDataKey . fromIntegral) configTemplateID) (MachineTemplateData (T.pack configTemplateName))
    pure ()

deployTemplatesAdmin = "deployment-admin"
deployTemplatesCreator = "deployment-create"
deployTemplateAlloc = "deployment-alloc"
deployInstanceAdmin = "deployment-instance-admin"

templateSearchFilter :: IntrospectResponse -> [Filter DeploymentTemplateData]
templateSearchFilter InactiveToken = error "Unreachable"
templateSearchFilter (ActiveToken { .. }) = if deployTemplatesAdmin `elem` tokenRealmRoles then [] else
  [ DeploymentTemplateDataOwnerId ==. fromMaybe "" tokenUUID ]

getPagedDeploymentTemplates :: Maybe Int -> BearerWrapper -> AppT (PagedResponse [DeploymentTemplate])
getPagedDeploymentTemplates pageN (BearerWrapper token) = do
  ~t@(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  let page = max 1 $ fromMaybe 1 pageN
  let filters = templateSearchFilter t
  templatesTotal <- runDB $ count filters
  templates <- runDB $ selectList filters [OffsetBy $ (page - 1) * pageSize, LimitTo pageSize, Desc DeploymentTemplateDataId]
  hiddenGroups <- runDB $ mapM (\v -> selectList [ DeploymentTemplateHideDeployment ==. entityKey v ] []) templates
  pure $ PagedResponse
    { responseObjects = map (\(e, g) -> DeploymentTemplate
      { templateVMs=(deploymentTemplateDataVms . entityVal) e
      , templateTitle=(deploymentTemplateDataTitle . entityVal) e
      , templateOwner=(deploymentTemplateDataOwnerId . entityVal) e
      , templateId=(fromIntegral . fromSqlKey . entityKey) e
      , templateExistingNetworks=(deploymentTemplateDataExistingNetworks . entityVal) e
      , templateAvaiableVMs=(deploymentTemplateDataAvailableVMs . entityVal) e
      , templateHiddenFor=map (deploymentTemplateHideGroup . entityVal) g
      , templateSnapshotPolicy=(deploymentTemplateDataSnapshotPolicy . entityVal) e
      }) (zip templates hiddenGroups)
    , responsePageSize=pageSize
    , responseTotal=templatesTotal
    }

createDeploymentTemplate :: DeploymentCreate -> BearerWrapper -> AppT ()
createDeploymentTemplate (DeploymentCreate { .. }) (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  if isNothing tokenUUID then sendJSONError err401 (JSONError "invalidToken" "Token has no UUID" Null) else do
    titleTaken <- runDB $ exists [ DeploymentTemplateDataTitle ==. reqTitle ]
    if titleTaken then sendJSONError err400 (JSONError "titleTaken" "Title is not unique" (object [ "message" .= String "Название шаблона занято" ])) else do
      _ <- runDB $ insert
        (DeploymentTemplateData
        { deploymentTemplateDataVms=reqVMs
        , deploymentTemplateDataTitle=reqTitle
        , deploymentTemplateDataOwnerId=fromJust tokenUUID
        , deploymentTemplateDataExistingNetworks=reqExistingNetworks
        , deploymentTemplateDataAvailableVMs=reqAvailableVMs
        , deploymentTemplateDataSnapshotPolicy=reqSnapshotPolicy
        })
      jobEnv <- asks $ getEnvFor JobserviceAPI
      _ <- withTokenVariable'' $ \t -> defaultRetryClientC jobEnv (insertJobserviceMessage (JobserviceTask Nothing JobserviceUpdateUsedImages {}) (BearerWrapper t))
      pure ()

getDeploymentTemplate :: Int -> BearerWrapper -> AppT DeploymentTemplate
getDeploymentTemplate tID (BearerWrapper token) = do
  t <- requireToken token
  let templateKey = DeploymentTemplateDataKey . fromIntegral $ tID
  template' <- runDB $ get (DeploymentTemplateDataKey . fromIntegral $ tID)
  case template' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Template not found" Null)
    (Just (DeploymentTemplateData { .. })) -> do
      isOwner <- isDeploymentTemplateOwner t templateKey
      if not isOwner then sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        groups <- runDB $ selectList [ DeploymentTemplateHideDeployment ==. templateKey ] [] <&> map (deploymentTemplateHideGroup . entityVal)
        pure $ DeploymentTemplate
          { templateAvaiableVMs = deploymentTemplateDataAvailableVMs
          , templateExistingNetworks = deploymentTemplateDataExistingNetworks
          , templateId = tID
          , templateOwner = deploymentTemplateDataOwnerId
          , templateTitle = deploymentTemplateDataTitle
          , templateVMs = deploymentTemplateDataVms
          , templateHiddenFor = groups
          , templateSnapshotPolicy = deploymentTemplateDataSnapshotPolicy
          }

deleteDeploymentTemplate :: Int -> BearerWrapper -> AppT ()
deleteDeploymentTemplate tID (BearerWrapper token) = do
  t <- requireToken token
  let templateKey = DeploymentTemplateDataKey . fromIntegral $ tID
  template' <- runDB $ get templateKey
  case template' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Template not found" Null)
    (Just (DeploymentTemplateData { .. })) -> do
      isOwner <- isDeploymentTemplateOwner t templateKey
      if not isOwner then sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        instancesExist <- runDB $ exists [ DeploymentInstanceDataParent ==. (DeploymentTemplateDataKey . fromIntegral $ tID)]
        if instancesExist then sendJSONError err400 (JSONError "badRequest" "There is left instances of this deployment" Null) else do
          runDB $ deleteWhere [ DeploymentTemplateHideDeployment ==. templateKey ]
          runDB $ delete templateKey
          jobEnv <- asks $ getEnvFor JobserviceAPI
          _ <- withTokenVariable'' $ \t -> defaultRetryClientC jobEnv (insertJobserviceMessage (JobserviceTask Nothing JobserviceUpdateUsedImages {}) (BearerWrapper t))
          pure ()

patchDeploymentTemplate :: Int -> DeploymentCreate -> BearerWrapper -> AppT ()
patchDeploymentTemplate tID (DeploymentCreate { .. }) (BearerWrapper token) = do
  t <- requireToken token
  let instanceKey = DeploymentTemplateDataKey . fromIntegral $ tID
  template' <- runDB $ exists [DeploymentTemplateDataId ==. instanceKey ]
  if not template' then sendJSONError err400 (JSONError "notFound" "Template not found" Null) else do
    isOwner <- isDeploymentTemplateOwner t instanceKey
    if not isOwner then sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
    else do
      titleTaken <- runDB $ exists [ DeploymentTemplateDataTitle ==. reqTitle, DeploymentTemplateDataId !=. instanceKey ]
      if titleTaken then sendJSONError err400 (JSONError "titleTaken" "Title is not unique" (object [ "message" .= String "Название шаблона занято" ])) else do
        runDB $ updateWhere [ DeploymentTemplateDataId ==. instanceKey ]
          [ DeploymentTemplateDataTitle =. reqTitle
          , DeploymentTemplateDataVms =. reqVMs
          , DeploymentTemplateDataAvailableVMs =. reqAvailableVMs
          , DeploymentTemplateDataExistingNetworks =. reqExistingNetworks
          , DeploymentTemplateDataSnapshotPolicy =. reqSnapshotPolicy
          ]
        jobEnv <- asks $ getEnvFor JobserviceAPI
        _ <- withTokenVariable'' $ \t -> defaultRetryClientC jobEnv (insertJobserviceMessage (JobserviceTask Nothing JobserviceUpdateUsedImages {}) (BearerWrapper t))
        pure ()

requestDeploymentVMID :: Text -> Text -> Maybe Int -> BearerWrapper -> AppT [Int]
requestDeploymentVMID _ _ Nothing (BearerWrapper token) = do
  _ <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplateAlloc]]
  sendJSONError err400 (JSONError "badRequest" "Amount is not specified" Null)
requestDeploymentVMID nodeName deploymentId (Just amount) (BearerWrapper token) = let
  allocateVMID :: DeploymentInstanceDataId -> Int -> [Int] -> AppT (Maybe [Int])
  allocateVMID dId amount = helper where
    helper :: [Int] -> AppT (Maybe [Int])
    helper [] = do
      allocatedVMID <- runDB $ count [ UsedVMIDUsedBy ==. dId ]
      if allocatedVMID >= amount then do
        vmids <- runDB $ selectList [ UsedVMIDUsedBy ==. dId ] [] <&> \x -> map (usedVMIDNum . entityVal) x
        pure $ Just vmids
      else do
        $(logError) "Lack of VMID pool!"
        runDB $ deleteWhere [ UsedVMIDUsedBy ==. dId ]
        pure Nothing
    helper (n:ns) = do
      allocatedVMID <- runDB $ count [ UsedVMIDUsedBy ==. dId ]
      if allocatedVMID >= amount then do
        vmids <- runDB $ selectList [ UsedVMIDUsedBy ==. dId ] [] <&> \x -> map (usedVMIDNum . entityVal) x
        pure $ Just vmids
      else do
        idHold <- runDB $ exists [ UsedVMIDNum ==. n ]
        if idHold then helper ns else do
          _ <- redisNXLockWrapper "global_vmid_lock" 5 (getUnixIntTime <&> fromIntegral) (liftIO (randomRIO (200_000, 800_000) >>= \v -> threadDelay v) >> helper (n:ns)) $ runDB (insert (UsedVMID {usedVMIDUsedBy=dId, usedVMIDNum=n})) >> pure Nothing
          helper ns
  in do
  when (amount > 100 || amount < 0) $ sendJSONError err400 (JSONError "badRequest" "Invalid VMID amount" Null)
  _ <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplateAlloc]]
  d <- runDB $ get (DeploymentInstanceDataKey deploymentId)
  case d of
    Nothing                                -> sendJSONError err404 (JSONError "notFound" "Instance not found" Null)
    (Just _) -> do
      clusterEnv <- asks $ getEnvFor ClusterManager
      clusterInfo <- withTokenVariable'' $ \t -> defaultRetryClientC clusterEnv $ getNodeByName nodeName (BearerWrapper t)
      mgr <- liftIO $ createProxmoxManagerRaw (Just $ nodeApiToken clusterInfo) (nodeIgnoreSSL clusterInfo)
      nodeUrl' <- liftIO $ tryParseUrl (T.unpack . nodeApiUrl $ clusterInfo)
      case nodeUrl' of
        (Left _) -> sendJSONError err500 (JSONError "serverError" "Failed to parse node URL" Null)
        (Right nodeUrl) -> do
          let state = ProxmoxState nodeUrl mgr
          activeNodes <- defaultRetryClientC' state P.getNodesVMMap
          case activeNodes of
            (Left e) -> do
              $(logError) $ T.pack $ "Failed to get nodes: " <> show e
              sendJSONError err500 (JSONError "serverError" "Failed to get node data" Null)
            (Right nodeMap) -> do
              let takenVMIDs = map fst $ M.toList nodeMap
              let idPool = filter (`notElem` takenVMIDs) [fromMaybe 100 (nodeStartVMID clusterInfo)..9999999]
              allocRes <- allocateVMID (DeploymentInstanceDataKey deploymentId) amount idPool
              case allocRes of
                Nothing -> sendJSONError err400 (JSONError "allocationFailure" "Failed to allocate VMID" Null)
                (Just vmid) -> pure vmid

requestDeploymentNetworks :: Text -> Text -> Maybe Int -> BearerWrapper -> AppT [String]
requestDeploymentNetworks _ _ Nothing (BearerWrapper token) = do
  _ <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplateAlloc]]
  sendJSONError err400 (JSONError "badRequest" "Amount is not specified" Null)
requestDeploymentNetworks nodeName deploymentId (Just amount) (BearerWrapper token) = let
  allocateNetworks :: DeploymentInstanceDataId -> Int -> [String] -> AppT (Maybe [String])
  allocateNetworks dId amount pool = do
    helper pool where
      helper :: [String] -> AppT (Maybe [String])
      helper [] = do
        allocatedNetworks <- runDB $ count [ UsedBridgesUsedBy ==. dId ]
        if allocatedNetworks >= amount then do
          nets <- runDB $ selectList [ UsedBridgesUsedBy ==. dId ] [] <&> \x -> map (T.unpack . usedBridgesName . entityVal) x
          pure $ Just nets
        else do
          $(logError) $ "Lack of network pool!"
          runDB $ deleteWhere [ UsedBridgesUsedBy ==. dId ]
          pure Nothing
      helper (n:ns) = do
        allocatedNetworks <- runDB $ count [ UsedBridgesUsedBy ==. dId ]
        if allocatedNetworks >= amount then do
          nets <- runDB $ selectList [ UsedBridgesUsedBy ==. dId ] [] <&> \x -> map (T.unpack . usedBridgesName . entityVal) x
          pure $ Just nets
        else do
          nameHold <- runDB $ exists [ UsedBridgesName ==. T.pack n ]
          if nameHold then helper ns else do
            _ <- redisNXLockWrapper "global_network_lock" 5 (getUnixIntTime <&> fromIntegral) (liftIO (randomRIO (200_000, 800_000) >>= \v -> threadDelay v) >> helper (n:ns)) $ runDB $ insert (UsedBridges {usedBridgesUsedBy=dId, usedBridgesName=T.pack n}) >> pure Nothing
            helper ns
  in do
  when (amount > 100 || amount < 0) $ sendJSONError err400 (JSONError "badRequest" "Invalid network amount" Null)
  _ <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplateAlloc]]
  d <- runDB $ get (DeploymentInstanceDataKey deploymentId)
  case d of
    Nothing                                -> sendJSONError err404 (JSONError "notFound" "Instance not found" Null)
    (Just _) -> do
      clusterEnv <- asks $ getEnvFor ClusterManager
      clusterInfo <- withTokenVariable'' $ \t -> defaultRetryClientC clusterEnv $ getNodeByName nodeName (BearerWrapper t)
      mgr <- liftIO $ createProxmoxManagerRaw (Just $ nodeApiToken clusterInfo) (nodeIgnoreSSL clusterInfo)
      nodeUrl' <- liftIO $ tryParseUrl (T.unpack . nodeApiUrl $ clusterInfo)
      case nodeUrl' of
        (Left _) -> sendJSONError err500 (JSONError "serverError" "Failed to parse node URL" Null)
        (Right nodeUrl) -> do
          let state = ProxmoxState nodeUrl mgr
          bridges <- defaultRetryClientC' state $ P.getBridgeNodeNetworks nodeName
          case bridges of
            (Left e) -> do
              $(logError) $ T.pack $ "Failed to get bridges: " <> show e
              sendJSONError err500 (JSONError "serverError" "Failed to get node data" Null)
            (Right bridgesList) -> do
              let bridgesNames = map proxmoxNetworkInterface bridgesList
              let sdnNamesPool = filter (`notElem` bridgesNames) $ iterLetters 8
              allocRes <- allocateNetworks (DeploymentInstanceDataKey deploymentId) amount sdnNamesPool
              case allocRes of
                Nothing -> sendJSONError err400 (JSONError "allocationFailure" "Failed to allocate networks" Null)
                (Just networks) -> pure networks

requestDeploymentDisplay :: Text -> Text -> Maybe Int -> BearerWrapper -> AppT [Int]
requestDeploymentDisplay _ _ Nothing (BearerWrapper token) = do
  _ <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplateAlloc]]
  sendJSONError err400 (JSONError "badRequest" "Amount is not specified" Null)
requestDeploymentDisplay nodeName deploymentId (Just amount) (BearerWrapper token) = let
  allocateDisplays :: Text -> DeploymentInstanceDataId -> Int -> [Int] -> AppT (Maybe [Int])
  allocateDisplays node dId amount = helper where
    helper :: [Int] -> AppT (Maybe [Int])
    helper [] = do
      allocatedDisplays <- runDB $ count [ UsedDisplayUsedBy ==. dId ]
      if allocatedDisplays >= amount then do
        displays <- runDB $ selectList [ UsedDisplayUsedBy ==. dId ] [] <&> \x -> map (usedDisplayNum . entityVal) x
        pure $ Just displays
      else do
        $(logError) "Lack of display pool!"
        runDB $ deleteWhere [ UsedDisplayUsedBy ==. dId ]
        pure Nothing
    helper (n:ns) = do
      allocatedDisplays <- runDB $ count [ UsedDisplayUsedBy ==. dId ]
      if allocatedDisplays >= amount then do
        displays <- runDB $ selectList [ UsedDisplayUsedBy ==. dId ] [] <&> \x -> map (usedDisplayNum . entityVal) x
        pure $ Just displays
      else do
        displayHold <- runDB $ exists [ UsedDisplayNum ==. n, UsedDisplayNodeName ==. node ]
        if displayHold then helper ns else do
          _ <- redisNXLockWrapper "global_display_lock" 5 (getUnixIntTime <&> fromIntegral) (liftIO (randomRIO (200_000, 800_000) >>= \v -> threadDelay v) >> helper (n:ns)) $ runDB $ insert (UsedDisplay {usedDisplayUsedBy=dId, usedDisplayNum=n, usedDisplayNodeName=node}) >> pure Nothing
          helper ns
  in do
    when (amount > 100 || amount < 0) $ sendJSONError err400 (JSONError "badRequest" "Invalid VMID amount" Null)
    _ <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplateAlloc]]
    d <- runDB $ get (DeploymentInstanceDataKey deploymentId)
    case d of
      Nothing                                -> sendJSONError err404 (JSONError "notFound" "Instance not found" Null)
      (Just _) -> do
        clusterEnv <- asks $ getEnvFor ClusterManager
        clusterInfo <- withTokenVariable'' $ \t -> defaultRetryClientC clusterEnv $ getNodeByName nodeName (BearerWrapper t)
        allocRes <- allocateDisplays nodeName (DeploymentInstanceDataKey deploymentId) amount [x | x <- [nodeMinDisplay clusterInfo..nodeMaxDisplay clusterInfo], 5900 + x `notElem` nodeExcludedPorts clusterInfo]
        case allocRes of
          Nothing -> sendJSONError err400 (JSONError "allocationFailure" "Failed to allocate displays" Null)
          (Just displays) -> pure displays

callGroupDeployment :: Int -> Maybe Text -> BearerWrapper -> AppT ()
callGroupDeployment tID groupName (BearerWrapper token) = do
  ~t@(ActiveToken { .. }) <- requireToken token
  case groupName of
    Nothing -> sendJSONError err400 (JSONError "badRequest" "Group name is not set" Null)
    (Just "") -> sendJSONError err400 (JSONError "badRequest" "Group name is not set" Null)
    (Just group) -> do
      let templateKey = DeploymentTemplateDataKey . fromIntegral $ tID
      template' <- runDB $ exists [ DeploymentTemplateDataId ==. templateKey ]
      if not template' then sendJSONError err404 (JSONError "notFound" "Template not found" Null) else do
        isOwner <- isDeploymentTemplateOperator t templateKey
        if not isOwner then sendJSONError err403 (JSONError "notOwner" "You're not administrator of template!" Null)
        else do
          Config { .. } <- ask
          r <- withTokenVariable' $ \t -> do
            defaultRetryClientC authEnv (getPagedGroupMembers group (BearerWrapper t) Nothing)
          case r of
            (Left _)  -> sendJSONError err400 (JSONError "badRequest" "Cant get group members" Null)
            (Right _) -> do
              $(logInfo) $ "Sending group deployment of template " <> (T.pack . show) tID <> " for group " <> group
              putTask tasksPool (GroupDeployment tID group tokenUUID)
              pure ()

callInstanceSnapshot :: Text -> Maybe Text -> Maybe Text -> Bool -> Bool -> BearerWrapper -> AppT ()
callInstanceSnapshot _ (Just "") _ _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)
callInstanceSnapshot _ Nothing _ _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)
callInstanceSnapshot instanceKey (Just snapName) mask' doDelete doRollback (BearerWrapper token) = do
  ~t@ActiveToken { .. } <- requireToken token
  d <- runDB $ get (DeploymentInstanceDataKey instanceKey)
  case d of
    Nothing                                -> sendJSONError err404 (JSONError "notFound" "Instance not found" Null)
    (Just (DeploymentInstanceData { deploymentInstanceDataParent = deploymentInstanceDataParent, .. })) -> do
      isOperator <- isDeploymentTemplateOperator t deploymentInstanceDataParent
      if not isOperator then sendJSONError err403 (JSONError "notOwner" "You're not operator of template!" Null)
      else do
        if not $ matchSnapshotRequirements (T.unpack snapName) then sendJSONError err400 (JSONError "badRequest" "Bad snapshot name" Null) else do
          jobserviceEnv <- asks $ getEnvFor JobserviceAPI
          let meta = JobserviceMessageMeta {deploymentAuthorId=tokenUUID, deploymentGroup=Nothing, deploymentUserId=Just deploymentInstanceDataOwnerId, templateId=(fromIntegral . fromSqlKey) deploymentInstanceDataParent, deploymentId=instanceKey}
          let taskF t m= defaultRetryClient jobserviceEnv $ J.insertJobserviceMessage (JobserviceTask (Just meta) m) (BearerWrapper t)
          withTokenVariable'' $ \t -> do
            case (doDelete, doRollback) of
              (False, False) -> taskF t (JobserviceSnapshot {deploymentSnapshot=snapName, deploymentDelete=False, deploymentMask=fromMaybe "*" mask', deploymentSnapshotComment = ""})
              (True, _) -> taskF t (JobserviceSnapshot {deploymentSnapshot=snapName, deploymentDelete=True, deploymentMask=fromMaybe "*" mask', deploymentSnapshotComment = ""})
              (False, True) -> taskF t (JobserviceRollback snapName $ fromMaybe "*" mask')

callGroupSnapshot :: Int -> Maybe Text -> Maybe Text -> Maybe Text -> Bool -> Bool -> BearerWrapper -> AppT ()
callGroupSnapshot _ (Just "") _ _ _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)
callGroupSnapshot _ _ (Just "") _ _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)
callGroupSnapshot tID (Just groupName) (Just snapName) mask' doDelete doRollback (BearerWrapper token) = do
  if not $ matchSnapshotRequirements (T.unpack snapName) then sendJSONError err400 (JSONError "badRequest" "Bad snapshot name" Null) else do
    t <- requireToken token
    let templateKey = DeploymentTemplateDataKey . fromIntegral $ tID
    template' <- runDB $ exists [ DeploymentTemplateDataId ==. templateKey ]
    if not template' then sendJSONError err404 (JSONError "notFound" "Template not found" Null) else do
      isOperator <- isDeploymentTemplateOperator t templateKey
      if not isOperator then sendJSONError err403 (JSONError "notOwner" "You're not operator of template!" Null)
      else do
        Config { .. } <- ask
        r <- withTokenVariable' $ \t -> do
          defaultRetryClientC authEnv (getPagedGroupMembers groupName (BearerWrapper t) Nothing)
        case r of
          (Left _) -> sendJSONError err400 (JSONError "badRequest" "Cant get group members" Null)
          (Right _) -> do
            let mask = fromMaybe "*" mask'
            case (doDelete, doRollback) of
              (False, False) -> putTask tasksPool (GroupMakeSnapshot tID groupName snapName mask)
              (True, _) -> putTask tasksPool (GroupDeleteSnapshot tID groupName snapName mask)
              (False, True) -> putTask tasksPool (GroupRollback tID groupName snapName mask)
callGroupSnapshot _ _ _ _ _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)

switchTemplateVisibility :: Int -> Maybe Text -> BearerWrapper -> AppT ()
switchTemplateVisibility _ Nothing _ = sendJSONError err400 (JSONError "badRequest" "Group is not set" Null)
switchTemplateVisibility templateId (Just group) (BearerWrapper token) = do
  t <- requireToken token
  let templateKey = DeploymentTemplateDataKey . fromIntegral $ templateId
  isAdmin <- isDeploymentTemplateAdministrator t templateKey
  if not isAdmin then sendJSONError err403 (JSONError "notOwner" "You're not admin of template!" Null)
  else do
    let filter' = [ DeploymentTemplateHideDeployment ==. templateKey, DeploymentTemplateHideGroup ==. group ]
    ruleExists <- runDB $ exists filter'
    if ruleExists then do
      runDB $ deleteWhere filter'
    else do
      _ <- runDB $ insert (DeploymentTemplateHide {deploymentTemplateHideGroup=group, deploymentTemplateHideDeployment=templateKey})
      pure ()

-- TODO: unify with function upper
callGroupDestroy :: Int -> Maybe Text -> BearerWrapper -> AppT ()
callGroupDestroy tID groupName (BearerWrapper token) = do
  ~t@(ActiveToken { .. }) <- requireToken token
  case groupName of
    Nothing -> sendJSONError err400 (JSONError "badRequest" "Group name is not set" Null)
    (Just "") -> sendJSONError err400 (JSONError "badRequest" "Group name is not set" Null)
    (Just group) -> do
      let templateKey = DeploymentTemplateDataKey . fromIntegral $ tID
      template' <- runDB $ exists [ DeploymentTemplateDataId ==. templateKey ]
      if not template' then sendJSONError err404 (JSONError "notFound" "Template not found" Null) else do
        isAdmin <- isDeploymentTemplateAdministrator t templateKey
        if not isAdmin then sendJSONError err403 (JSONError "notOwner" "You're not admin of template!" Null)
        else do
          Config { .. } <- ask
          r <- withTokenVariable' $ \t -> do
            defaultRetryClientC authEnv (getPagedGroupMembers group (BearerWrapper t) Nothing)
          case r of
            (Left _) -> sendJSONError err400 (JSONError "badRequest" "Cant get group members" Null)
            (Right _) -> do
              $(logInfo) $ "Sending group deployment of template " <> (T.pack . show) tID <> " for group " <> group
              putTask tasksPool (GroupDestroy tID group tokenUUID)
              pure ()

callGroupPower :: Int -> Maybe Text -> Maybe Text -> Bool -> BearerWrapper -> AppT ()
callGroupPower tID (Just group) mask' powerOn (BearerWrapper token) = do
  t <- requireToken token
  let instanceKey = DeploymentTemplateDataKey . fromIntegral $ tID
  template' <- runDB $ exists [ DeploymentTemplateDataId ==. instanceKey ]
  if not template' then sendJSONError err400 (JSONError "notFound" "Template not found" Null) else do
    isOperator <- isDeploymentTemplateOperator t instanceKey
    if not isOperator then sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
    else do
      Config { .. } <- ask
      r <- withTokenVariable' $ \t -> do
        defaultRetryClientC authEnv (getPagedGroupMembers group (BearerWrapper t) Nothing)
      case r of
        (Left _) -> sendJSONError err400 (JSONError "badRequest" "Cant get group members" Null)
        (Right _) -> do
          putTask tasksPool (GroupPower tID group powerOn (fromMaybe "*" mask'))
          pure ()
callGroupPower _ _ _ _ _ = do
  sendJSONError err400 (JSONError "badRequest" "Group is not specified!" Null)

setDeploymentInstancePower = undefined

deploymentInstanceKey :: DeploymentInstanceData -> Text
deploymentInstanceKey e = deploymentInstanceDataOwnerId e <> "-" <>
  (T.pack . show . (fromIntegral :: (Integral a) => a -> Int) . fromSqlKey . deploymentInstanceDataParent) e

callInstanceDestroy :: Text -> BearerWrapper -> AppT ()
callInstanceDestroy instanceKey (BearerWrapper token) = do
  ~t@ActiveToken { .. } <- requireToken token
  d <- runDB $ get (DeploymentInstanceDataKey instanceKey)
  case d of
    Nothing                                -> sendJSONError err404 (JSONError "notFound" "Instance not found" Null)
    (Just (DeploymentInstanceData { .. })) -> do
      isAdministrator <- isDeploymentTemplateAdministrator t deploymentInstanceDataParent
      if not isAdministrator then sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        jobserviceEnv <- asks $ getEnvFor JobserviceAPI
        _ <- withTokenVariable'' $ \t -> defaultRetryClient jobserviceEnv (insertJobserviceMessage (JobserviceTask (Just JobserviceMessageMeta {deploymentUserId=Just deploymentInstanceDataOwnerId, deploymentGroup=Nothing, deploymentAuthorId=tokenUUID, templateId=(fromIntegral . fromSqlKey) deploymentInstanceDataParent, deploymentId=instanceKey}) (JobserviceDestroyInstance {})) (BearerWrapper t))
        pure ()

generateGroupDeploymentFilter :: Maybe Text -> AppT [Filter DeploymentInstanceData]
generateGroupDeploymentFilter Nothing = pure []
generateGroupDeploymentFilter (Just "") = pure []
generateGroupDeploymentFilter (Just group) = do
  Config { .. } <- ask
  r <- withTokenVariable' $ \t -> do
    defaultRetryClientC authEnv (getAllGroupMembers group (BearerWrapper t))
  case r of
    (Left _) -> sendJSONError err400 (JSONError "badRequest" "Cant get group members" Null)
    (Right users) -> pure [DeploymentInstanceDataOwnerId <-. map userID users]

patchDeploymentInstance :: Text -> DeploymentPatch -> BearerWrapper -> AppT ()
patchDeploymentInstance dId patch (BearerWrapper token) = let
  generatePatch :: DeploymentPatch -> [Update DeploymentInstanceData]
  generatePatch (DeploymentPatch { .. }) =
    [DeploymentInstanceDataDeployConfig =. patchInstanceDeployConfig | isJust patchInstanceDeployConfig] <>
    [DeploymentInstanceDataNetworkNamesMap =. fromJust patchInstanceNetworkMap | isJust patchInstanceNetworkMap] <>
    [DeploymentInstanceDataState =. fromJust patchInstanceState | isJust patchInstanceState] <>
    [DeploymentInstanceDataVmLinks =. fromJust patchInstanceVMLinks | isJust patchInstanceVMLinks]
  in do
  _ <- requireManyRealmRoles token [[deployInstanceAdmin]]
  let instanceKey = DeploymentInstanceDataKey dId
  instanceExists <- runDB $ exists [ DeploymentInstanceDataId ==. instanceKey ]
  if not instanceExists then sendJSONError err404 (JSONError "notFound" "Instance not found" Null) else do
    let ts = generatePatch patch
    _ <- runDB $ updateWhere [ DeploymentInstanceDataId ==. instanceKey ] ts
    pure ()

getDeploymentInstancesStats :: Int -> Maybe Text -> BearerWrapper -> AppT DeploymentStats
getDeploymentInstancesStats tID targetGroup (BearerWrapper token) = do
  t <- requireToken token
  let instanceKey = DeploymentTemplateDataKey . fromIntegral $ tID
  template' <- runDB $ exists [ DeploymentTemplateDataId ==.instanceKey ]
  if not template' then sendJSONError err400 (JSONError "notFound" "Template not found" Null) else do
    isOwner <- isDeploymentTemplateOwner t instanceKey
    if not isOwner then sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
    else do
      f <- generateGroupDeploymentFilter targetGroup
      (failedAmount, destroyingAmount, deployingAmount, deployedAmount, createdAmount) <- runDB $ do
        f1 <- count $ [ DeploymentInstanceDataParent ==. instanceKey, DeploymentInstanceDataState ==. Failed ] <> f
        f2 <- count $ [ DeploymentInstanceDataParent ==. instanceKey, DeploymentInstanceDataState ==. Destroying ] <> f
        f3 <- count $ [ DeploymentInstanceDataParent ==. instanceKey, DeploymentInstanceDataState ==. Deploying ] <> f
        f4 <- count $ [ DeploymentInstanceDataParent ==. instanceKey, DeploymentInstanceDataState ==. Deployed ] <> f
        f5 <- count $ [ DeploymentInstanceDataParent ==. instanceKey, DeploymentInstanceDataState ==. Created ] <> f
        pure (f1, f2, f3, f4, f5)
      pure (DeploymentStats {failedAmount=failedAmount, destroyingAmount=destroyingAmount, deployingAmount=deployingAmount, deployedAmount=deployedAmount, createdAmount=createdAmount})

getDeploymentTemplateInstances :: Int -> Maybe Int -> Maybe Text -> BearerWrapper -> AppT (PagedResponse [DeploymentInstanceBrief])
getDeploymentTemplateInstances tID pageN targetGroup (BearerWrapper token) = do
  t <- requireToken token
  let templateKey = DeploymentTemplateDataKey . fromIntegral $ tID
  template' <- runDB $ get templateKey
  case template' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Template not found" Null)
    (Just (DeploymentTemplateData { .. })) -> do
      isOwner <- isDeploymentTemplateOwner t templateKey
      if not isOwner then
        sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        f <- generateGroupDeploymentFilter targetGroup
        let page = max 1 $ fromMaybe 1 pageN
        instancesCount <- runDB . count $ [ DeploymentInstanceDataParent ==. (DeploymentTemplateDataKey . fromIntegral $ tID)] <> f
        instances <- runDB $ selectList ([ DeploymentInstanceDataParent ==. (DeploymentTemplateDataKey . fromIntegral $ tID)] <> f) [LimitTo pageSize, OffsetBy $ pageSize * (page - 1)]
        pure $ PagedResponse
          { responseObjects=map
            (\e -> DeploymentInstanceBrief
              { briefDeploymentUser=(deploymentInstanceDataOwnerId . entityVal) e
              , briefDeploymentTitle=deploymentTemplateDataTitle
              , briefDeploymentStatus=(deploymentInstanceDataState . entityVal) e
              , briefDeploymentId=deploymentInstanceKey (entityVal e)
              }) instances
          , responsePageSize=pageSize
          , responseTotal=instancesCount
          }

getMyTemplateInstances :: Maybe Int -> BearerWrapper -> AppT (PagedResponse [DeploymentInstanceBrief])
getMyTemplateInstances pageN (BearerWrapper token) = let

  helper :: [DeploymentInstanceBrief] -> [Entity DeploymentInstanceData] -> AppT [DeploymentInstanceBrief]
  helper acc [] = (pure . reverse) acc
  helper acc ((Entity _ e):l) = do
    ~(Just (DeploymentTemplateData { .. })) <- runDB $ get (deploymentInstanceDataParent e)
    let brief = DeploymentInstanceBrief {
        briefDeploymentUser=deploymentInstanceDataOwnerId e
      , briefDeploymentTitle=deploymentTemplateDataTitle
      , briefDeploymentStatus=deploymentInstanceDataState e
      , briefDeploymentId=deploymentInstanceKey e
      }
    helper (brief:acc) l

  in do
  ~(ActiveToken { .. }) <- requireToken token
  case tokenUUID of
    Nothing -> $(logWarn) "Empty token UUID" >> pure (PagedResponse {responseObjects=[], responsePageSize=0, responseTotal=0})
    (Just userId) -> do
      let page = max 1 $ fromMaybe 1 pageN
      let isAdmin = deployTemplatesAdmin `elem` tokenRealmRoles
      hiddenTemplates <- runDB $ selectList [ DeploymentTemplateHideGroup <-. tokenGroups ] [] <&> map (deploymentTemplateHideDeployment . entityVal)
      ownedTemplates <- runDB $ selectKeysList [ DeploymentTemplateDataOwnerId ==. userId ] []
      -- TODO: fix after groups
      let filter' = if not isAdmin then [ DeploymentInstanceDataOwnerId ==. userId ] <> ([ DeploymentInstanceDataParent <-. ownedTemplates ] ||. [ DeploymentInstanceDataParent /<-. hiddenTemplates ]) else [ DeploymentInstanceDataOwnerId ==. userId ]
      instancesCount <- runDB $ count filter'
      instances <- runDB $ selectList filter' [LimitTo pageSize, OffsetBy $ pageSize * (page - 1)]
      r <- helper [] instances
      pure $ PagedResponse
        { responseObjects=r
        , responsePageSize=pageSize
        , responseTotal=instancesCount
        }

deleteDeploymentInstance :: Text -> BearerWrapper -> AppT ()
deleteDeploymentInstance instanceId (BearerWrapper token) = do
  t <- requireToken token
  instance' <- runDB $ get (DeploymentInstanceDataKey instanceId)
  case instance' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Instance not found" Null)
    (Just (DeploymentInstanceData { .. })) -> do
      isOwner <- isDeploymentTemplateOwner t deploymentInstanceDataParent
      if not isOwner then sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else runDB $ delete (DeploymentInstanceDataKey instanceId)

getDeploymentInstance :: Text -> BearerWrapper -> AppT DeploymentInstance
getDeploymentInstance instanceId (BearerWrapper token) = do
  ~t@ActiveToken { .. } <- requireToken token
  instance' <- runDB $ get (DeploymentInstanceDataKey instanceId)
  case instance' of
    Nothing -> sendJSONError err404 (JSONError "deploymentNotFound" "Deployment not found" Null)
    (Just (DeploymentInstanceData { .. })) -> do
      deploymentTemplateDataHidden <- runDB $
        exists [ DeploymentTemplateHideDeployment ==. deploymentInstanceDataParent, DeploymentTemplateHideGroup <-. tokenGroups ]
      ~(Just (DeploymentTemplateData { .. })) <- runDB $ get deploymentInstanceDataParent
      deploymentOwnership <- isDeploymentOwner t (DeploymentInstanceDataKey instanceId)
      if deploymentOwnership == NotOwner then sendJSONError err403 (JSONError "notOwner" "You do not own this instance!" Null) else do
        if deploymentOwnership == DeploymentOwner && deploymentTemplateDataHidden then do
          sendJSONError err403 (JSONError "instanceHidden" "Instance is hidden" Null) else do
            let base = DeploymentInstance { instanceVMLinks=M.mapKeys T.pack $ M.map T.pack (if deploymentOwnership == TemplateOwner then deploymentInstanceDataVmLinks else M.filterWithKey (\k _ -> T.pack k `elem` deploymentTemplateDataAvailableVMs) deploymentInstanceDataVmLinks)
              , instanceUser=deploymentInstanceDataOwnerId
              , instanceTitle=deploymentTemplateDataTitle
              , instanceState=deploymentInstanceDataState
              , instanceOf=(fromIntegral . fromSqlKey) deploymentInstanceDataParent
              , instanceLogs=if deploymentOwnership /= TemplateOwner then [] else deploymentInstanceDataLogs
              , instanceDeployConfig=if deploymentOwnership /= TemplateOwner then Nothing else deploymentInstanceDataDeployConfig
              , instanceVMPower = M.empty
              , instanceNetworkMap=if deploymentOwnership /= TemplateOwner then Nothing else Just deploymentInstanceDataNetworkNamesMap
              }
            case deploymentInstanceDataDeployConfig of
              Nothing -> pure base
              (Just d@(DeployConfig { deployVMs = vms, deployParameters = DeployParams { deployNodeName = nodeName, deployUrl = nodeUrl } })) -> do
                url <- liftIO $ parseBaseUrl (T.unpack nodeUrl)
                mgr <- liftIO $ createProxmoxManager d
                let state = ProxmoxState url mgr
                vmMap' <- defaultRetryClient' state $ P.getNodeVMsMap nodeName
                case vmMap' of
                  (Left _) -> pure base
                  (Right vmMap) -> do
                    let definedVMs = M.fromList $ map (\(p, n) -> (T.pack n, (== VMRunning) . vmStatus $ fromJust p)) $ filter (\(p, _) -> isJust p) $ map (\v-> (M.lookup (fromJust $ configVMID v) vmMap, configVMName v)) $ filter (isJust . configVMID) vms
                    pure $ base { instanceVMPower = definedVMs }

getVMPortPower :: Text -> BearerWrapper -> AppT PowerState
getVMPortPower vmPort (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  case tokenUUID of
    Nothing -> sendJSONError err401 (JSONError "invalidToken" "" Null)
    (Just uid) -> do
      hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
      if not hasAccess then sendJSONError err403 (JSONError "noAccess" "" Null) else do
        ~(Just (vmConfig, instanceData)) <- findVMByPort vmPort
        let vmid = fromJust $ configVMID vmConfig
        case deploymentInstanceDataDeployConfig instanceData of
          Nothing -> sendJSONError err400 (JSONError "" "" Null)
          (Just deployConfig@(DeployConfig { deployParameters = DeployParams { deployUrl = url', deployNodeName = nodeName } })) -> do
            mgr <- liftIO $ createProxmoxManager deployConfig
            url <- liftIO $ parseBaseUrl (T.unpack url')
            let state = ProxmoxState url mgr
            power' <- defaultRetryClient' state $ P.getVMPower nodeName vmid
            case power' of
              (Left e) -> do
                $(logError) $ "Proxmox error response: " <> (T.pack . show) e
                sendJSONError err500 (JSONError "internalError" "" Null)
              (Right (ProxmoxResponse resp _)) -> do
                case resp of
                  Nothing  -> sendJSONError err400 (JSONError "" "" Null)
                  (Just (ProxmoxVMStatusWrapper VMRunning)) -> pure (PowerState True)
                  (Just (ProxmoxVMStatusWrapper VMStopped)) -> pure (PowerState False)
                  (Just (ProxmoxVMStatusWrapper (VMUnknown vmStatus))) -> do
                    $(logError) $ "Got unknown VM power status: " <> vmStatus
                    pure (PowerState False)

switchVMPortPower :: Text -> BearerWrapper -> AppT PowerState
switchVMPortPower vmPort (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  case tokenUUID of
    Nothing -> sendJSONError err401 (JSONError "invalidToken" "" Null)
    (Just uid) -> do
      hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
      if not hasAccess then sendJSONError err403 (JSONError "noAccess" "" Null) else do
        ~(Just (vmConfig, instanceData)) <- findVMByPort vmPort
        let vmid = fromJust $ configVMID vmConfig
        case deploymentInstanceDataDeployConfig instanceData of
          Nothing -> sendJSONError err400 (JSONError "" "" Null)
          (Just deployConfig@(DeployConfig { deployParameters = DeployParams { deployUrl = url', deployNodeName = nodeName } })) -> do
            mgr <- liftIO $ createProxmoxManager deployConfig
            url <- liftIO $ parseBaseUrl (T.unpack url')
            let state = ProxmoxState url mgr
            power' <- defaultRetryClient' state $ P.getVMPower nodeName vmid
            case power' of
              (Left e) -> do
                $(logError) $ "Proxmox error response: " <> (T.pack . show) e
                sendJSONError err500 (JSONError "internalError" "" Null)
              (Right (ProxmoxResponse resp _)) -> do
                case resp of
                  Nothing  -> sendJSONError err400 (JSONError "" "" Null)
                  (Just (ProxmoxVMStatusWrapper vmPower)) -> do
                    lockExists <- getStringValue ("powerlock-" <> T.unpack vmPort) <&> isJust
                    if lockExists then ($(logInfo) $ "Powerlock on " <> vmPort) >> pure (PowerState $ vmPower == VMRunning) else do
                      _ <- cacheValue' ("powerlock-" <> T.unpack vmPort) "1" (Just 10)
                      let f = if vmPower == VMRunning then P.stopVM else P.startVM
                      _ <- defaultRetryClient' state $ f nodeName vmid
                      pure (PowerState (vmPower /= VMRunning))

getUndeployedVMAmount :: BearerWrapper -> AppT (M.Map Text Int)
getUndeployedVMAmount (BearerWrapper token) = let
  f :: [DeploymentInstanceData] -> M.Map Text Int -> M.Map Text Int
  f [] acc = acc
  f ((DeploymentInstanceData { deploymentInstanceDataDeployConfig=Nothing}):ds) acc = f ds acc
  f ((DeploymentInstanceData { deploymentInstanceDataDeployConfig=Just (DeployConfig {deployParameters=(DeployParams {deployNodeName=deployNodeName}), deployVMs=vms})}):ds) acc = do
    let vmAmount = length vms
    case M.lookup deployNodeName acc of
      Nothing     -> f ds (M.insert deployNodeName vmAmount acc)
      (Just oldV) -> f ds (M.insert deployNodeName (vmAmount + oldV) acc)
  in do
  _ <- requireRealmRoles token ["cluster-admin"]
  deployments <- runDB $ selectList [ DeploymentInstanceDataState <-. [Created, Deploying], DeploymentInstanceDataDeployConfig !=. Nothing ] []
  pure (f (map entityVal deployments) M.empty)

getVMPortNetworks :: Text -> BearerWrapper -> AppT (M.Map String String)
getVMPortNetworks vmPort (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  case tokenUUID of
    Nothing -> sendJSONError err401 (JSONError "invalidToken" "" Null)
    (Just uid) -> do
      hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
      if not hasAccess then sendJSONError err403 (JSONError "noAccess" "" Null) else do
        ~(Just (vmConfig, instanceData)) <- findVMByPort vmPort
        let vmid = fromJust $ configVMID vmConfig
        case deploymentInstanceDataDeployConfig instanceData of
          Nothing -> sendJSONError err400 (JSONError "" "" Null)
          (Just deployConfig@(DeployConfig { deployParameters = DeployParams { deployUrl = url', deployNodeName = nodeName } })) -> do
            mgr <- liftIO $ createProxmoxManager deployConfig
            url <- liftIO $ parseBaseUrl (T.unpack url')
            let state = ProxmoxState url mgr
            vmConfig' <- defaultRetryClient' state $ P.getVMConfig nodeName vmid
            case vmConfig' of
              (Right (ProxmoxResponse (Just vmCfg) _)) -> do
                let devicesMap = vmNetworkDevices vmCfg
                let reversedNames = (M.fromList . map (\(a, b) -> (b, a)) . M.toList) $ deploymentInstanceDataNetworkNamesMap instanceData
                let netMap = suggestNetworkBridges (map snd (M.toList devicesMap)) reversedNames
                pure netMap
              _ -> sendJSONError err500 (JSONError "internalError" "" Null)

vmPortAccessCheck :: Text -> BearerWrapper -> AppT ()
vmPortAccessCheck vmPort (BearerWrapper token) = do
  r <- lookupToken token
  case r of
    InactiveToken -> sendJSONError err401 (JSONError "" "" Null)
    (ActiveToken { tokenUUID = Nothing }) -> sendJSONError err401 (JSONError "" "" Null)
    (ActiveToken { tokenUUID = Just uid,.. }) -> do
      hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
      if not hasAccess then sendJSONError err403 (JSONError "" "" Null) else pure ()

postInstanceLog :: Text -> Text -> BearerWrapper -> AppT ()
postInstanceLog instanceId logLine (BearerWrapper token) = do
  t <- requireToken token
  instance' <- runDB $ get (DeploymentInstanceDataKey instanceId)
  case instance' of
    Nothing -> sendJSONError err404 (JSONError "deploymentNotFound" "Deployment not found" Null)
    (Just (DeploymentInstanceData { .. })) -> do
      isOwner <- isDeploymentTemplateOwner t deploymentInstanceDataParent
      if not isOwner then sendJSONError err403 (JSONError "notOwner" "You do not own this instance!" Null) else do
        runDB $ updateWhere [ DeploymentInstanceDataId ==. DeploymentInstanceDataKey instanceId ] [ DeploymentInstanceDataLogs =. deploymentInstanceDataLogs ++ [logLine] ]
        pure ()

getVMPortSnapshots :: Text -> AppT (DeploymentSnapshotPolicy, Entity DeploymentInstanceData, [ProxmoxSnapshot], ConfigVM)
getVMPortSnapshots vmPort = do
  ~(Just (d@(Entity _ DeploymentInstanceData { .. }), vmData)) <- findInstanceByVMPort vmPort
  ~(Just (DeploymentTemplateData { deploymentTemplateDataSnapshotPolicy = p@DeploymentSnapshotPolicy { .. }, .. })) <- runDB $ get deploymentInstanceDataParent
  case deploymentInstanceDataDeployConfig of
    Nothing -> pure (p, d, [], vmData)
    (Just cfg@(DeployConfig { deployParameters = DeployParams { deployUrl=deployUrl, deployNodeName=deployNodeName } })) -> do
      mgr <- liftIO $ createProxmoxManager cfg
      nodeUrl' <- liftIO $ tryParseUrl (T.unpack deployUrl)
      case nodeUrl' of
        (Left _) -> sendJSONError err500 (JSONError "serverError" "Failed to parse node URL" Null)
        (Right nodeUrl) -> do
          let state = ProxmoxState nodeUrl mgr
          snapshots' <- defaultRetryClientC' state $ P.getVMSnapshots deployNodeName (fromMaybe 0 $ configVMID vmData)
          case snapshots' of
            (Left e) -> do
              $(logError) $ T.pack $ "Error getting snapshots: " <> show e
              sendJSONError err500 (JSONError "Internal error" "Failed to get snapshots" Null)
            (Right (ProxmoxResponse { proxmoxData = snapshots })) -> pure (p, d, snapshots, vmData)

listVMPortSnapshots :: Text -> BearerWrapper -> AppT [ProxmoxSnapshot]
listVMPortSnapshots vmPort t@(BearerWrapper token) = let
  f t = do
    (DeploymentSnapshotPolicy { .. }, Entity _ DeploymentInstanceData { .. }, snapshots, _) <- getVMPortSnapshots vmPort
    isAdmin <- isDeploymentTemplateAdministrator t deploymentInstanceDataParent
    if deploymentSnapshotQuota <= 0 && not deploymentSnapshotUseAny && not isAdmin then pure (Just []) else do
      let snapshots' = sortOn (Down . fromMaybe 0 . snapshotTime) $ filter ((/=) "current" . snapshotName) snapshots
      if deploymentSnapshotUseAny || isAdmin then (pure . Just) snapshots' else
        (pure . Just) $ filter ((==) "usermade" . snapshotDescription) snapshots'
  in do
  ~t@(ActiveToken { .. }) <- requireToken token
  let uid = fromMaybe "" tokenUUID
  hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
  if not hasAccess then sendJSONError err403 (JSONError "forbidden" "You dont have access to VM!" Null) else do
    getOrCacheJsonValue (Just 10) (T.unpack $ "snapshots-" <> vmPort <> "-" <> uid) (f t) <&> fromRight (error "Unreachable")

getVMPortSnapshotPolicy :: Text -> BearerWrapper -> AppT DeploymentSnapshotPolicy
getVMPortSnapshotPolicy vmPort (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  let uid = fromMaybe "" tokenUUID
  hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
  if not hasAccess then sendJSONError err403 (JSONError "forbidden" "You dont have access to VM!" Null) else do
    ~(Just (Entity _ DeploymentInstanceData { .. }, _)) <- findInstanceByVMPort vmPort
    ~(Just (DeploymentTemplateData { .. })) <- runDB $ get deploymentInstanceDataParent
    pure deploymentTemplateDataSnapshotPolicy

rateLimitResponse :: AppT a
rateLimitResponse = sendJSONError err409 (JSONError "ratelimit" "Too many requests" $ object ["message" .= String "Слишком много одновременных запросов к серверу. Попробуйте отправить запрос позднее."])

snapshotRequestLimit :: AppT a
snapshotRequestLimit = sendJSONError err409 (JSONError "ratelimit" "One job was already created recently" $ object ["message" .= String "В недавнее время был отправлен запрос на работу со снапшотами. Попробуйте повторить запрос через 10 секунд."])

deploymentLockedResponse :: AppT a
deploymentLockedResponse = sendJSONError err409 (JSONError "ratelimit" "Deployment is locked now" $ object ["message" .= String "Над стендом уже выполняется какое-то действие. Попробуйте повторить запрос позже."])

takeVMPortSnapshot :: Text -> Maybe Text -> BearerWrapper -> AppT ()
takeVMPortSnapshot vmPort Nothing (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  -- TODO: remove separate lock key
  -- now its using because function calls other branch of function, which
  -- will cause double ratelock
  let uid = fromMaybe "" tokenUUID
  hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
  if not hasAccess then sendJSONError err403 (JSONError "forbidden" "You dont have access to VM!" Null) else do
    redisRateLockWrapper (T.unpack $ "snapshot-rate-" <> vmPort <> "-" <> uid <> "-noname") 5 rateLimitResponse $ do
      (_, _, snapshots, _) <- getVMPortSnapshots vmPort
      let snapNames = map snapshotName snapshots
      let snapList = filter (`notElem` snapNames) $ map (T.pack . ("snap" <>) . show) [1..100]
      case snapList of
        [] -> sendJSONError err500 (JSONError "internalError" "Cant generate snapshot name" Null)
        (snapName:_) -> takeVMPortSnapshot vmPort (Just snapName) (BearerWrapper token)
takeVMPortSnapshot vmPort (Just snapName) (BearerWrapper token) = do
  ~t@(ActiveToken { .. }) <- requireToken token
  let uid = fromMaybe "" tokenUUID
  hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
  if not hasAccess then sendJSONError err403 (JSONError "forbidden" "You dont have access to VM!" Null) else do
    redisRateLockWrapper (T.unpack $ "snapshot-rate-" <> vmPort <> "-" <> uid) 3 rateLimitResponse $ do
      (DeploymentSnapshotPolicy { .. }, Entity (DeploymentInstanceDataKey dId) DeploymentInstanceData { .. }, snapshots, vmData) <- getVMPortSnapshots vmPort
      let userSnapshotsAmount = length $ filter ((==) "usermade" . snapshotDescription) snapshots
      isAdmin <- isDeploymentTemplateAdministrator t deploymentInstanceDataParent
      unless (isAdmin || deploymentSnapshotQuota > 0) $ sendJSONError err403 (JSONError "forbidden" "You cant make snapshots" $ object ["message" .= String "У вас нет прав на создание снапшотов!"])
      when (userSnapshotsAmount >= deploymentSnapshotQuota && not isAdmin) $ sendJSONError err400 (JSONError "badRequest" "Too many snapshots are made" $ object ["message" .= String "Сделано слишком много снапшотов!"])
      let nameTaken = any ((==) snapName . snapshotName) snapshots
      when nameTaken $ sendJSONError err400 (JSONError "badRequest" "Snapshot name taken" $ object ["message" .= String "Имя снапшота занято"])
      unless (matchSnapshotRequirements . T.unpack $ snapName) $ sendJSONError err400 (JSONError "badRequest" "Bad snapshot name" $ object ["message" .= String "Название снапшота не подходит по требованиям"])
      jobserviceEnv <- asks $ getEnvFor JobserviceAPI
      withTokenVariable'' $ \t' -> do
        locked <- defaultRetryClient jobserviceEnv $ isDeploymentLocked dId AnyLock (BearerWrapper t')
        when (isLeft locked || locked == Right True) $ deploymentLockedResponse
        let meta = JobserviceMessageMeta {deploymentUserId=Just deploymentInstanceDataOwnerId, deploymentGroup=Nothing, deploymentAuthorId=tokenUUID, templateId=(fromIntegral . fromSqlKey) deploymentInstanceDataParent, deploymentId=dId}
        redisRateLockWrapper (T.unpack $ "snapshot-request-" <> vmPort <> "-" <> uid) 10 snapshotRequestLimit $ do
          defaultRetryClient jobserviceEnv $ insertJobserviceMessage (JobserviceTask (Just meta) (JobserviceSnapshot snapName False (T.pack $ configVMName vmData) (if not isAdmin then "usermade" else ""))) (BearerWrapper t')

deleteVMPortSnapshot :: Text -> Maybe Text -> BearerWrapper -> AppT ()
deleteVMPortSnapshot _ Nothing _ = sendJSONError err400 (JSONError "badRequest" "Missing snapshot name" Null)
deleteVMPortSnapshot vmPort (Just snapName) (BearerWrapper token) = do
  ~t@(ActiveToken { .. }) <- requireToken token
  let uid = fromMaybe "" tokenUUID
  hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
  if not hasAccess then sendJSONError err403 (JSONError "forbidden" "You dont have access to VM!" Null) else do
    redisRateLockWrapper (T.unpack $ "snapshot-rate-" <> vmPort <> "-" <> uid) 3 rateLimitResponse $ do
      (DeploymentSnapshotPolicy { .. }, Entity (DeploymentInstanceDataKey dId) DeploymentInstanceData { .. }, snapshots, vmData) <- getVMPortSnapshots vmPort
      let userSnapshots = map snapshotName $ filter ((==) "usermade" . snapshotDescription) snapshots
      isAdmin <- isDeploymentTemplateAdministrator t deploymentInstanceDataParent
      unless (isAdmin || deploymentSnapshotDeleteAny || deploymentSnapshotDeleteOwned) $ sendJSONError err403 (JSONError "forbidden" "You cant delete snapshots" $ object ["message" .= String "У вас нет прав на удаление снапшотов!"])
      when (snapName `notElem` userSnapshots && not deploymentSnapshotDeleteAny && not isAdmin) $ sendJSONError err403 (JSONError "forbidden" "You cant delete not owned templates" $ object ["message" .= String "Вы не можете удалить данный снапшот"])
      let nameTaken = any ((==) snapName . snapshotName) snapshots
      unless nameTaken $ sendJSONError err404 (JSONError "badRequest" "Snapshot is not found" $ object ["message" .= String "Снапшот не найден"])
      unless (matchSnapshotRequirements . T.unpack $ snapName) $ sendJSONError err400 (JSONError "badRequest" "Bad snapshot name" $ object ["message" .= String "Название снапшота не подходит по требованиям"])
      jobserviceEnv <- asks $ getEnvFor JobserviceAPI
      withTokenVariable'' $ \t' -> do
        locked <- defaultRetryClient jobserviceEnv $ isDeploymentLocked dId AnyLock (BearerWrapper t')
        when (isLeft locked || locked == Right True) deploymentLockedResponse
        let meta = JobserviceMessageMeta {deploymentUserId=Just deploymentInstanceDataOwnerId, deploymentGroup=Nothing, deploymentAuthorId=tokenUUID, templateId=(fromIntegral . fromSqlKey) deploymentInstanceDataParent, deploymentId=dId}
        redisRateLockWrapper (T.unpack $ "snapshot-request-" <> vmPort <> "-" <> uid) 10 snapshotRequestLimit $ do
          defaultRetryClient jobserviceEnv $ insertJobserviceMessage (JobserviceTask (Just meta) (JobserviceSnapshot snapName True (T.pack $ configVMName vmData) "")) (BearerWrapper t')

rollbackVMPort :: Text -> Maybe Text -> BearerWrapper -> AppT ()
rollbackVMPort _ Nothing _ = sendJSONError err400 (JSONError "badRequest" "Missing snapshot name" Null)
rollbackVMPort vmPort (Just snapName) (BearerWrapper token) = do
  ~t@(ActiveToken { .. }) <- requireToken token
  let uid = fromMaybe "" tokenUUID
  hasAccess <- isUserAccessedVMPort tokenGroups tokenRealmRoles uid vmPort
  if not hasAccess then sendJSONError err403 (JSONError "forbidden" "You dont have access to VM!" Null) else do
    redisRateLockWrapper (T.unpack $ "snapshot-rate-" <> vmPort <> "-" <> uid) 3 rateLimitResponse $ do
      (DeploymentSnapshotPolicy { .. }, Entity (DeploymentInstanceDataKey dId) DeploymentInstanceData { .. }, snapshots, vmData) <- getVMPortSnapshots vmPort
      isAdmin <- isDeploymentTemplateAdministrator t deploymentInstanceDataParent
      let snapshots' = map snapshotName . sortOn (Down . fromMaybe 0 . snapshotTime) . filter ((/=) "current" . snapshotName) . filter (if not isAdmin && not deploymentSnapshotUseAny then ((==) "usermade" . snapshotDescription) else const True) $ snapshots
      if deploymentSnapshotQuota <= 0 && not deploymentSnapshotUseAny && not isAdmin then do
        sendJSONError err403 (JSONError "forbidden" "You cant rollback VM!" $ object ["message" .= String "У вас нет квоты снапшотов или права на использование всех снапшотов!"])
        else do
          case find (snapName ==) snapshots' of
            Nothing -> sendJSONError err404 (JSONError "badRequest" "Snapshot is not found" $ object ["message" .= String "Снапшот не найден"])
            (Just _) -> do
                jobserviceEnv <- asks $ getEnvFor JobserviceAPI
                withTokenVariable'' $ \t' -> do
                  locked <- defaultRetryClient jobserviceEnv $ isDeploymentLocked dId AnyLock (BearerWrapper t')
                  when (isLeft locked || locked == Right True) deploymentLockedResponse
                  redisRateLockWrapper (T.unpack $ "snapshot-request-" <> vmPort <> "-" <> uid) 10 snapshotRequestLimit $ do
                    let meta = JobserviceMessageMeta {deploymentUserId=Just deploymentInstanceDataOwnerId, deploymentGroup=Nothing, deploymentAuthorId=tokenUUID, templateId=(fromIntegral . fromSqlKey) deploymentInstanceDataParent, deploymentId=dId}
                    defaultRetryClient jobserviceEnv $ insertJobserviceMessage (JobserviceTask (Just meta) (JobserviceRollback snapName (T.pack $ configVMName vmData))) (BearerWrapper t')

deploymentServer :: ServerT DeploymentAPI AppT
deploymentServer = getPagedTemplates
  :<|> deleteTemplate
  :<|> createTemplate
  :<|> getPagedDeploymentTemplates
  :<|> createDeploymentTemplate
  :<|> getDeploymentTemplate
  :<|> deleteDeploymentTemplate
  :<|> patchDeploymentTemplate
  :<|> callGroupDeployment
  :<|> callGroupDestroy
  :<|> callGroupSnapshot
  :<|> callGroupPower
  :<|> requestDeploymentVMID
  :<|> requestDeploymentDisplay
  :<|> getDeploymentTemplateInstances
  :<|> getMyTemplateInstances
  :<|> getDeploymentInstance
  :<|> setDeploymentInstancePower
  :<|> getVMPortPower
  :<|> switchVMPortPower
  :<|> getVMPortNetworks
  :<|> vmPortAccessCheck
  :<|> getDeploymentInstancesStats
  :<|> callInstanceDestroy
  :<|> callInstanceSnapshot
  :<|> requestDeploymentNetworks
  :<|> patchDeploymentInstance
  :<|> getTemplateNameList
  :<|> deleteDeploymentInstance
  :<|> getUndeployedVMAmount
  :<|> postInstanceLog
  :<|> switchTemplateVisibility
  :<|> getVMPortSnapshotPolicy
  :<|> takeVMPortSnapshot
  :<|> deleteVMPortSnapshot
  :<|> listVMPortSnapshots
  :<|> rollbackVMPort
