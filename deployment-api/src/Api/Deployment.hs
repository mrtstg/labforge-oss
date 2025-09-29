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
{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE TypeOperators     #-}
module Api.Deployment
  ( deploymentServer
  , deploymentInstanceKey
  ) where

import           Api
import           Api.Keycloak.Models
import           Api.Keycloak.Models.Introspect
import           Api.Keycloak.Models.User
import           Api.Keycloak.Utils
import           Api.Retry
import           Auth
import           Auth.Client
import           Auth.Token
import           Config
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import           Data.Functor                             ((<&>))
import qualified Data.Map                                 as M
import           Data.Maybe
import           Data.Text                                (Text)
import qualified Data.Text                                as T
import           Database
import           Database.Persist
import           Database.Persist.Postgresql
import           Deployment.Models.Deployment
import           Deployment.Models.Stats
import           Deployment.Schema
import           Models
import           Models.JSONError
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
import           Proxmox.Models.VM
import           Proxmox.Models.VMConfig
import           Proxmox.Retry                            (defaultRetryClient')
import           Proxmox.Schema
import           Redis.Common
import           Servant
import           Servant.Client
import           Text.Read                                (read, readMaybe)
import           Utils

templateAdminRole = "image-admin"
templateReadRole = "image-view"
pageSize = 20

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
  templateExists <- runDB $ exists [ MachineTemplateDataId ==. (toSqlKey . fromIntegral) templateID ]
  if not templateExists then sendJSONError err404 (JSONError "notFound" "Template not found" Null) else do
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
  pure $ PagedResponse
    { responseObjects = map (\e -> DeploymentTemplate
      { templateVMs=(deploymentTemplateDataVms . entityVal) e
      , templateTitle=(deploymentTemplateDataTitle . entityVal) e
      , templateOwner=(deploymentTemplateDataOwnerId . entityVal) e
      , templateId=(fromIntegral . fromSqlKey . entityKey) e
      , templateExistingNetworks=(deploymentTemplateDataExistingNetworks . entityVal) e
      , templateAvaiableVMs=(deploymentTemplateDataAvailableVMs . entityVal) e
      }) templates
    , responsePageSize=pageSize
    , responseTotal=templatesTotal
    }

createDeploymentTemplate :: DeploymentCreate -> BearerWrapper -> AppT ()
createDeploymentTemplate (DeploymentCreate { .. }) (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  if isNothing tokenUUID then sendJSONError err401 (JSONError "invalidToken" "Token has no UUID" Null) else do
    titleTaken <- runDB $ exists [ DeploymentTemplateDataTitle ==. reqTitle ]
    if titleTaken then sendJSONError err400 (JSONError "titleTaken" "Title is not unique" Null) else do
      _ <- runDB $ insert
        (DeploymentTemplateData
        { deploymentTemplateDataVms=reqVMs
        , deploymentTemplateDataTitle=reqTitle
        , deploymentTemplateDataOwnerId=fromJust tokenUUID
        , deploymentTemplateDataExistingNetworks=reqExistingNetworks
        , deploymentTemplateDataAvailableVMs=reqAvailableVMs
        })
      pure ()

getDeploymentTemplate :: Int -> BearerWrapper -> AppT DeploymentTemplate
getDeploymentTemplate tID (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  template' <- runDB $ get (DeploymentTemplateDataKey . fromIntegral $ tID)
  case template' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Template not found" Null)
    (Just (DeploymentTemplateData { .. })) -> do
      if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
        sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        pure $ DeploymentTemplate
          { templateAvaiableVMs = deploymentTemplateDataAvailableVMs
          , templateExistingNetworks = deploymentTemplateDataExistingNetworks
          , templateId = tID
          , templateOwner = deploymentTemplateDataOwnerId
          , templateTitle = deploymentTemplateDataTitle
          , templateVMs = deploymentTemplateDataVms
          }

deleteDeploymentTemplate :: Int -> BearerWrapper -> AppT ()
deleteDeploymentTemplate tID (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  template' <- runDB $ get (DeploymentTemplateDataKey . fromIntegral $ tID)
  case template' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Template not found" Null)
    (Just (DeploymentTemplateData { .. })) -> do
      if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
        sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        runDB $ delete (DeploymentTemplateDataKey . fromIntegral $ tID)
        pure ()

patchDeploymentTemplate :: Int -> DeploymentCreate -> BearerWrapper -> AppT ()
patchDeploymentTemplate tID (DeploymentCreate { .. }) (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  let instanceKey = (DeploymentTemplateDataKey . fromIntegral $ tID)
  template' <- runDB $ get instanceKey
  case template' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Template not found" Null)
    (Just (DeploymentTemplateData { .. })) -> do
      if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
        sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        titleTaken <- runDB $ exists [ DeploymentTemplateDataTitle ==. reqTitle, DeploymentTemplateDataId !=. instanceKey ]
        if titleTaken then sendJSONError err400 (JSONError "titleTaken" "Title is not unique" Null) else do
          runDB $ updateWhere [ DeploymentTemplateDataId ==. instanceKey ]
            [ DeploymentTemplateDataTitle =. reqTitle
            , DeploymentTemplateDataVms =. reqVMs
            , DeploymentTemplateDataAvailableVMs =. reqAvailableVMs
            , DeploymentTemplateDataExistingNetworks =. reqExistingNetworks
            ]
          pure ()

requestDeploymentVMID = undefined
requestDeploymentDisplay = undefined

callGroupDeployment :: Int -> Maybe Text -> BearerWrapper -> AppT ()
callGroupDeployment tID groupName (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  case groupName of
    Nothing -> sendJSONError err400 (JSONError "badRequest" "Group name is not set" Null)
    (Just "") -> sendJSONError err400 (JSONError "badRequest" "Group name is not set" Null)
    (Just group) -> do
      template' <- runDB $ get (DeploymentTemplateDataKey . fromIntegral $ tID)
      case template' of
        Nothing -> sendJSONError err404 (JSONError "notFound" "Template not found" Null)
        (Just (DeploymentTemplateData { .. })) -> do
          if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
            sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
          else do
            Config { .. } <- ask
            r <- withTokenVariable' $ \t -> do
              defaultRetryClientC authEnv (getPagedGroupMembers group (BearerWrapper t) Nothing)
            case r of
              (Left _) -> sendJSONError err400 (JSONError "badRequest" "Cant get group members" Null)
              (Right _) -> do
                $(logInfo) $ "Sending group deployment of template " <> (T.pack . show) tID <> " for group " <> group
                putTask tasksPool (GroupDeployment tID group)
                pure ()

callInstanceSnapshot :: Text -> Maybe Text -> Bool -> Bool -> BearerWrapper -> AppT ()
callInstanceSnapshot _ (Just "") _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)
callInstanceSnapshot _ Nothing _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)
callInstanceSnapshot instanceKey (Just snapName) doDelete doRollback (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  d <- runDB $ get (DeploymentInstanceDataKey instanceKey)
  case d of
    Nothing                                -> sendJSONError err404 (JSONError "notFound" "Instance not found" Null)
    (Just (DeploymentInstanceData { .. })) -> do
      ~(Just (DeploymentTemplateData { .. })) <- runDB $ get deploymentInstanceDataParent
      if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
        sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        Config { .. } <- ask
        if not $ matchSnapshotRequirements (T.unpack snapName) then sendJSONError err400 (JSONError "badRequest" "Bad snapshot name" Null) else do
          case (doDelete, doRollback) of
            (False, False) -> putTask tasksPool (DeploymentMakeSnapshot instanceKey snapName)
            (True, _) -> putTask tasksPool (DeploymentDeleteSnapshot instanceKey snapName)
            (False, True) -> putTask tasksPool (RollbackInstance instanceKey snapName)

callGroupSnapshot :: Int -> Maybe Text -> Maybe Text -> Bool -> Bool -> BearerWrapper -> AppT ()
callGroupSnapshot _ (Just "") _ _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)
callGroupSnapshot _ _ (Just "") _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)
callGroupSnapshot tID (Just groupName) (Just snapName) doDelete doRollback (BearerWrapper token) = do
  if not $ matchSnapshotRequirements (T.unpack snapName) then sendJSONError err400 (JSONError "badRequest" "Bad snapshot name" Null) else do
    ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
    template' <- runDB $ get (DeploymentTemplateDataKey . fromIntegral $ tID)
    case template' of
      Nothing -> sendJSONError err404 (JSONError "notFound" "Template not found" Null)
      (Just (DeploymentTemplateData { .. })) -> do
        if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
          sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
        else do
          Config { .. } <- ask
          r <- withTokenVariable' $ \t -> do
            defaultRetryClientC authEnv (getPagedGroupMembers groupName (BearerWrapper t) Nothing)
          case r of
            (Left _) -> sendJSONError err400 (JSONError "badRequest" "Cant get group members" Null)
            (Right _) -> do
              case (doDelete, doRollback) of
                (False, False) -> putTask tasksPool (GroupMakeSnapshot tID groupName snapName)
                (True, _) -> putTask tasksPool (GroupDeleteSnapshot tID groupName snapName)
                (False, True) -> putTask tasksPool (GroupRollback tID groupName snapName)
callGroupSnapshot _ _ _ _ _ _ = sendJSONError err400 (JSONError "badRequest" "Snapshot or group is not specified" Null)

-- TODO: unify with function upper
callGroupDestroy :: Int -> Maybe Text -> BearerWrapper -> AppT ()
callGroupDestroy tID groupName (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  case groupName of
    Nothing -> sendJSONError err400 (JSONError "badRequest" "Group name is not set" Null)
    (Just "") -> sendJSONError err400 (JSONError "badRequest" "Group name is not set" Null)
    (Just group) -> do
      template' <- runDB $ get (DeploymentTemplateDataKey . fromIntegral $ tID)
      case template' of
        Nothing -> sendJSONError err404 (JSONError "notFound" "Template not found" Null)
        (Just (DeploymentTemplateData { .. })) -> do
          if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
            sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
          else do
            Config { .. } <- ask
            r <- withTokenVariable' $ \t -> do
              defaultRetryClientC authEnv (getPagedGroupMembers group (BearerWrapper t) Nothing)
            case r of
              (Left _) -> sendJSONError err400 (JSONError "badRequest" "Cant get group members" Null)
              (Right _) -> do
                $(logInfo) $ "Sending group deployment of template " <> (T.pack . show) tID <> " for group " <> group
                putTask tasksPool (GroupDestroy tID group)
                pure ()

callGroupPower :: Int -> Maybe Text -> Bool -> BearerWrapper -> AppT ()
callGroupPower tID (Just group) powerOn (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  let instanceKey = DeploymentTemplateDataKey . fromIntegral $ tID
  template' <- runDB $ get instanceKey
  case template' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Template not found" Null)
    (Just (DeploymentTemplateData { .. })) -> do
      if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
        sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        Config { .. } <- ask
        r <- withTokenVariable' $ \t -> do
          defaultRetryClientC authEnv (getPagedGroupMembers group (BearerWrapper t) Nothing)
        case r of
          (Left _) -> sendJSONError err400 (JSONError "badRequest" "Cant get group members" Null)
          (Right _) -> do
            putTask tasksPool (GroupPower tID group powerOn)
            pure ()
callGroupPower _ _ _ _ = do
  sendJSONError err400 (JSONError "badRequest" "Group is not specified!" Null)

setDeploymentInstancePower = undefined

deploymentInstanceKey :: DeploymentInstanceData -> Text
deploymentInstanceKey e = deploymentInstanceDataOwnerId e <> "-" <>
  (T.pack . show . (fromIntegral :: (Integral a) => a -> Int) . fromSqlKey . deploymentInstanceDataParent) e

callInstanceDestroy :: Text -> BearerWrapper -> AppT ()
callInstanceDestroy instanceKey (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  d <- runDB $ get (DeploymentInstanceDataKey instanceKey)
  case d of
    Nothing                                -> sendJSONError err404 (JSONError "notFound" "Instance not found" Null)
    (Just (DeploymentInstanceData { .. })) -> do
      ~(Just (DeploymentTemplateData { .. })) <- runDB $ get deploymentInstanceDataParent
      if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
        sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
      else do
        Config { .. } <- ask
        putTask tasksPool (DestroyInstance instanceKey)
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

getDeploymentInstancesStats :: Int -> Maybe Text -> BearerWrapper -> AppT DeploymentStats
getDeploymentInstancesStats tID targetGroup (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  let instanceKey = DeploymentTemplateDataKey . fromIntegral $ tID
  template' <- runDB $ get instanceKey
  case template' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Template not found" Null)
    (Just (DeploymentTemplateData { .. })) -> do
      if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
        sendJSONError err403 (JSONError "notOwner" "You're not owner of template!" Null)
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
  ~(ActiveToken { .. }) <- requireManyRealmRoles token [[deployTemplatesAdmin], [deployTemplatesCreator]]
  template' <- runDB $ get (DeploymentTemplateDataKey . fromIntegral $ tID)
  case template' of
    Nothing -> sendJSONError err400 (JSONError "notFound" "Template not found" Null)
    (Just (DeploymentTemplateData { .. })) -> do
      if deployTemplatesAdmin `notElem` tokenRealmRoles && tokenUUID /= Just deploymentTemplateDataOwnerId then
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
      instancesCount <- runDB $ count [ DeploymentInstanceDataOwnerId ==. userId ]
      instances <- runDB $ selectList [ DeploymentInstanceDataOwnerId ==. userId ] [LimitTo pageSize, OffsetBy $ pageSize * (page - 1)]
      r <- helper [] instances
      pure $ PagedResponse
        { responseObjects=r
        , responsePageSize=pageSize
        , responseTotal=instancesCount
        }

getDeploymentInstance :: Text -> BearerWrapper -> AppT DeploymentInstance
getDeploymentInstance instanceId (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  let isAdmin = deployTemplatesAdmin `elem` tokenRealmRoles
  instance' <- runDB $ get (DeploymentInstanceDataKey instanceId)
  case instance' of
    Nothing -> sendJSONError err404 (JSONError "deploymentNotFound" "Deployment not found" Null)
    (Just (DeploymentInstanceData { .. })) -> do
      ~(Just (DeploymentTemplateData { .. })) <- runDB $ get deploymentInstanceDataParent
      if Just deploymentTemplateDataOwnerId /= tokenUUID && Just deploymentInstanceDataOwnerId /= tokenUUID && not isAdmin then sendJSONError err403 (JSONError "notOwner" "You do not own this instance!" Null) else do
        let base = DeploymentInstance { instanceVMLinks=M.mapKeys T.pack $ M.map T.pack (if isAdmin then deploymentInstanceDataVmLinks else M.filterWithKey (\k _ -> T.pack k `elem` deploymentTemplateDataAvailableVMs) deploymentInstanceDataVmLinks)
          , instanceUser=deploymentInstanceDataOwnerId
          , instanceTitle=deploymentTemplateDataTitle
          , instanceState=deploymentInstanceDataState
          , instanceOf=(fromIntegral . fromSqlKey) deploymentInstanceDataParent
          , instanceLogs=if not isAdmin then [] else deploymentInstanceDataLogs
          , instanceDeployConfig=if not isAdmin then Nothing else deploymentInstanceDataDeployConfig
          , instanceVMPower = M.empty
          , instanceNetworkMap=if not isAdmin then Nothing else Just deploymentInstanceDataNetworkNamesMap
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
      hasAccess <- isUserAccessedVMPort uid vmPort
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
      hasAccess <- isUserAccessedVMPort uid vmPort
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

getVMPortNetworks :: Text -> BearerWrapper -> AppT (M.Map String String)
getVMPortNetworks vmPort (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  case tokenUUID of
    Nothing -> sendJSONError err401 (JSONError "invalidToken" "" Null)
    (Just uid) -> do
      hasAccess <- isUserAccessedVMPort uid vmPort
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
      hasAccess <- isUserAccessedVMPort uid vmPort
      if not hasAccess then sendJSONError err403 (JSONError "" "" Null) else pure ()

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
