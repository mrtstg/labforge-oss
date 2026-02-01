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
import qualified Jobservice.Client                        as J
import           Jobservice.Models
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
        (ProxmoxResponse c _) <- P.getSDNNetworks Nothing
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
              $(logDebug) $ "Generated actions: " <> (pack . show) actions
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
        (ProxmoxResponse c _) <- P.getSDNNetworks Nothing
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
              let cleanedActions = leaveLastItem ApplySDNNetworks actions
              $(logDebug) $ "Generated actions: " <> (pack . show) cleanedActions
              result <- (liftIO . runExceptT) $ (runStateT (unTransaction executeTransaction) (planState { transactionActions = cleanedActions }))
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
handleTask _ (GroupDeployment tID groupName) = do
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
      jobserviceEnv <- asks $ getEnvFor JobserviceAPI
      mapM_ (\(DeploymentInstanceDataKey t) -> withTokenVariable $ \token -> defaultRetryClient jobserviceEnv $ J.insertJobserviceMessage (JobserviceDeployInstance t) (BearerWrapper token)) existingDeployments
      newDeployments <- createMissingDeployments (DeploymentTemplateDataKey $ fromIntegral tID) tID users
      mapM_ (\t -> withTokenVariable $ \token -> defaultRetryClient jobserviceEnv (J.insertJobserviceMessage (JobserviceAllocateNode t) (BearerWrapper token))) newDeployments
handleTask _ (GroupDestroy tID groupName) = do
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
        DeploymentInstanceDataState !=. Destroying,
        DeploymentInstanceDataState !=. Deploying,
        DeploymentInstanceDataDeployConfig !=. Nothing
        ] []
      jobserviceEnv <- asks $ getEnvFor JobserviceAPI
      mapM_ (\(DeploymentInstanceDataKey t) -> withTokenVariable $ \token -> defaultRetryClient jobserviceEnv $ J.insertJobserviceMessage (JobserviceDestroyInstance t) (BearerWrapper token)) existingDeployments
handleTask _ (GroupRollback tID groupName snapName mask) = do
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
      jobserviceEnv <- asks $ getEnvFor JobserviceAPI
      mapM_ (\(DeploymentInstanceDataKey t) -> withTokenVariable $ \token -> defaultRetryClient jobserviceEnv $ J.insertJobserviceMessage (JobserviceRollback t snapName mask) (BearerWrapper token)) existingDeployments
handleTask _ (GroupMakeSnapshot tID groupName snapName mask) = do
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
      jobserviceEnv <- asks $ getEnvFor JobserviceAPI
      mapM_ (\(DeploymentInstanceDataKey t) -> withTokenVariable $ \token -> defaultRetryClient jobserviceEnv $ J.insertJobserviceMessage (JobserviceSnapshot t snapName False mask) (BearerWrapper token)) existingDeployments
handleTask _ (GroupDeleteSnapshot tID groupName snapName mask) = do
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
      jobserviceEnv <- asks $ getEnvFor JobserviceAPI
      mapM_ (\(DeploymentInstanceDataKey t) -> withTokenVariable $ \token -> defaultRetryClient jobserviceEnv $ J.insertJobserviceMessage (JobserviceSnapshot t snapName True mask) (BearerWrapper token)) existingDeployments
handleTask _ (GroupPower tID groupName powerOn mask) = do
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
      jobserviceEnv <- asks $ getEnvFor JobserviceAPI
      mapM_ (\(DeploymentInstanceDataKey t) -> withTokenVariable $ \token -> defaultRetryClient jobserviceEnv $ J.insertJobserviceMessage (JobservicePower t powerOn mask) (BearerWrapper token)) existingDeployments
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
