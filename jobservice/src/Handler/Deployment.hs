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
module Handler.Deployment (deployInstance, destroyInstance) where

import           Api.BaseUrl
import           Api.Keycloak.Models
import           Api.Keycloak.Models.User
import           Api.Keycloak.Token
import           Api.Keycloak.Utils
import           Api.Retry
import           Auth.Client
import qualified Cluster.Client                           as C
import           Cluster.Models.Node
import           Config
import           Control.Monad.Except
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Control.Monad.State
import qualified Data.Map                                 as M
import           Data.Maybe
import           Data.Text                                (Text)
import qualified Data.Text                                as T
import qualified Deployment.Client                        as D
import           Deployment.Models.Deployment
import           Handler.Utils
import qualified Jobservice.Client                        as J
import           Jobservice.Models
import           Network.AMQP
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
import           Proxmox.Schema
import           Servant.Client
import           Service.Environment
import           Utils.Time

-- TODO: remove double with deployment API
leaveLastItem :: (Eq a) => a -> [a] -> [a]
leaveLastItem item = helper [] where
  helper acc [] = reverse acc
  helper acc (el:ls) = if el == item && hasItem item ls then helper acc ls else helper (el:acc) ls

hasItem :: (Eq a) => a -> [a] -> Bool
hasItem item = foldr (\ el -> (||) (item == el)) False

defaultErrorFallback :: JobserviceMessageMeta -> Envelope -> String -> AppT (Maybe a)
defaultErrorFallback m@(JobserviceMessageMeta {deploymentId=deploymentId}) env err = do
  $(logError) $ "[" <> deploymentId <> "]" <> T.pack err
  _ <- setDeploymentInstanceStatus m Failed
  pure Nothing

generateAndDeployTransaction :: DeployTarget -> JobserviceMessageMeta -> DeployConfig -> AppT Bool
generateAndDeployTransaction target taskMeta@(JobserviceMessageMeta { deploymentId=deploymentKey }) deployConfig@(DeployConfig { deployParameters = DeployParams {deployUrl=deployUrl, deployNodeName=nodeName} }) = do
  cfg <- ask
  parseRes <- liftIO $ tryParseUrl (T.unpack deployUrl)
  case parseRes of
    (Left e) -> do
      $(logError) $ "Failed to parse URL: " <> T.pack e
      _ <- setDeploymentInstanceStatus taskMeta Failed
      pure False
    (Right url) -> do
      deploymentEnv <- asks $ getEnvFor DeploymentService
      m <- liftIO $ createProxmoxManager deployConfig
      let stages = planTransactionStages deployConfig target
      let state = ProxmoxState url m
      let planState = TransactionState { transactionTarget=target
        , transactionProxmoxState=state
        , transactionLogFunction=sendLogRequest deploymentKey cfg
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
          $(logError) $ "Failed to get PVE data: " <> (T.pack . show) e
          _ <- withTokenVariable $ \token -> do
            defaultRetryClientC deploymentEnv $ D.postInstanceLog deploymentKey ("Не удалось получить данные от Proxmox: " <> (T.pack . show) e) (BearerWrapper token)
          _ <- setDeploymentInstanceStatus taskMeta Failed
          pure False
        (Right (a, b, c, d, e)) -> do
          planRes <- liftIO $ planTransactionActions stages a b c d e planState
          case planRes of
            (Left e) -> do
              let errorText = "Failed to plan transaction: " <> (T.pack . show) e
              $(logError) errorText
              _ <- withTokenVariable $ \token -> do
                defaultRetryClientC deploymentEnv $ D.postInstanceLog deploymentKey errorText (BearerWrapper token)
              _ <- setDeploymentInstanceStatus taskMeta Failed
              pure False
            (Right actions) -> do
              let cleanedActions = leaveLastItem UpdateNodeNetworks $ leaveLastItem ApplySDNNetworks actions
              $(logDebug) $ "Generated actions: " <> (T.pack . show) cleanedActions
              result <- (liftIO . runExceptT) $ (runStateT (unTransaction executeTransaction) (planState { transactionActions = cleanedActions }))
              case result of
                (Left e) -> do
                  let errorText = "Failed to run transaction: " <> (T.pack . show) e
                  $(logError) errorText
                  _ <- withTokenVariable $ \token -> do
                    defaultRetryClientC deploymentEnv $ D.postInstanceLog deploymentKey errorText (BearerWrapper token)
                  _ <- setDeploymentInstanceStatus taskMeta Failed
                  pure False
                (Right _) -> do
                  when (target == Deploy) $ do
                    _ <- setDeploymentInstanceStatus taskMeta Deployed
                    pure ()
                  pure True

deployInstance :: Envelope -> JobserviceMessageMeta -> AppT ()
deployInstance env m@(JobserviceMessageMeta {deploymentId=deploymentId, templateId = tId, ..}) = do
  let errorF = defaultErrorFallback m env
  deploymentEnv <- asks $ getEnvFor DeploymentService
  instance'' <- withTokenVariable $ \t -> do
    defaultRetryClient deploymentEnv $ D.getDeploymentInstance deploymentId (BearerWrapper t)
  instance' <- unpackError instance'' errorF
  case instance' of
    Nothing -> pure ()
    (Just (DeploymentInstance { .. })) -> do
      if instanceState `notElem` [Deployed, Deploying, Destroying] then do
        _ <- setDeploymentInstanceStatus m Deploying
        case instanceDeployConfig of
          Nothing -> do
            --_ <- setDeploymentInstanceStatus m Created
            errorF "Deployment config is not set"
            pure ()
          (Just deployConfig) -> do
            _ <- generateAndDeployTransaction Deploy m deployConfig
            pure ()
      else do
        pure ()
deployInstance _ _ = error "Invalid message"

destroyInstance :: Envelope -> JobserviceMessageMeta -> AppT ()
destroyInstance env m@(JobserviceMessageMeta {deploymentId=deploymentId, templateId = tId, .. }) = do
  let errorF = defaultErrorFallback m env
  deploymentEnv <- asks $ getEnvFor DeploymentService
  instance'' <- withTokenVariable $ \t -> do
    defaultRetryClient deploymentEnv $ D.getDeploymentInstance deploymentId (BearerWrapper t)
  instance' <- unpackError instance'' errorF
  case instance' of
    Nothing -> pure ()
    (Just (DeploymentInstance { .. })) -> do
      _ <- setDeploymentInstanceStatus m Destroying
      case instanceDeployConfig of
        Nothing -> do
          -- #TODO: log
          --_ <- setDeploymentInstanceStatus m Created
          --errorF "Deployment config is not set"
          deleteRes <- withTokenVariable $ \t -> do
            defaultRetryClient deploymentEnv $ D.deleteDeploymentInstance deploymentId (BearerWrapper t)
          d <- unpackError deleteRes errorF
          case d of
            Nothing -> pure ()
            (Just _) -> do
              pure ()
        (Just deployConfig) -> do
          deployed <- generateAndDeployTransaction Destroy m deployConfig
          when deployed $ do
            deleteRes <- withTokenVariable $ \t -> do
              defaultRetryClient deploymentEnv $ D.deleteDeploymentInstance deploymentId (BearerWrapper t)
            _ <- unpackError deleteRes errorF
            pure ()
