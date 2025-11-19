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

-- TODO: remove double with deployment API
leaveLastItem :: (Eq a) => a -> [a] -> [a]
leaveLastItem item = helper [] where
  helper acc [] = reverse acc
  helper acc (el:ls) = if el == item && hasItem item ls then helper acc ls else helper (el:acc) ls

hasItem :: (Eq a) => a -> [a] -> Bool
hasItem item = foldr (\ el -> (||) (item == el)) False

defaultErrorFallback :: Text -> Envelope -> String -> AppT (Maybe a)
defaultErrorFallback deploymentId env err = do
  $(logError) $ "[" <> deploymentId <> "]" <> T.pack err
  _ <- setDeploymentInstanceStatus deploymentId Failed
  pure Nothing

generateAndDeployTransaction :: DeployTarget -> Text -> DeployConfig -> AppT Bool
generateAndDeployTransaction target deploymentKey deployConfig@(DeployConfig { deployParameters = DeployParams {deployUrl=deployUrl, deployNodeName=nodeName} }) = do
  cfg <- ask
  parseRes <- liftIO $ tryParseUrl (T.unpack deployUrl)
  case parseRes of
    (Left e) -> do
      $(logError) $ "Failed to parse URL: " <> T.pack e
      -- addLogToDeploymentInstance deploymentKey $ "Failed to parse URL: " <> pack e
      _ <- setDeploymentInstanceStatus deploymentKey Failed
      pure False
    (Right url) -> do
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
          --addLogToDeploymentInstance deploymentKey $ "Failed to get PVE data: " <> (pack . show) e
          _ <- setDeploymentInstanceStatus deploymentKey Failed
          pure False
        (Right (a, b, c, d, e)) -> do
          planRes <- liftIO $ planTransactionActions stages a b c d e planState
          case planRes of
            (Left e) -> do
              $(logError) $ "Failed to plan transaction: " <> (T.pack . show) e
              --addLogToDeploymentInstance deploymentKey $ "Failed to plan transaction: " <> (pack . show) e
              _ <- setDeploymentInstanceStatus deploymentKey Failed
              pure False
            (Right actions) -> do
              let cleanedActions = leaveLastItem ApplySDNNetworks actions
              $(logDebug) $ "Generated actions: " <> (T.pack . show) cleanedActions
              result <- (liftIO . runExceptT) $ (runStateT (unTransaction executeTransaction) (planState { transactionActions = cleanedActions }))
              case result of
                (Left e) -> do
                  $(logError) $ "Failed to run transaction: " <> (T.pack . show) e
                  --addLogToDeploymentInstance deploymentKey $ "Failed to run transaction: " <> (pack . show) e
                  _ <- setDeploymentInstanceStatus deploymentKey Failed
                  pure False
                (Right _) -> do
                  setDeploymentInstanceStatus deploymentKey (if target == Deploy then Deployed else Created)
                  pure True

deployInstance :: Envelope -> Text -> AppT ()
deployInstance env deploymentId = do
  let errorF = defaultErrorFallback deploymentId env
  deploymentEnv <- asks $ getEnvFor DeploymentService
  instance'' <- withTokenVariable $ \t -> do
    defaultRetryClient deploymentEnv $ D.getDeploymentInstance deploymentId (BearerWrapper t)
  instance' <- unpackError instance'' errorF
  case instance' of
    Nothing -> pure ()
    (Just (DeploymentInstance { .. })) -> do
      when (instanceState `notElem` [Deployed, Deploying, Destroying]) $ do
        _ <- setDeploymentInstanceStatus deploymentId Deploying
        case instanceDeployConfig of
          Nothing -> do
            -- #TODO: log
            _ <- setDeploymentInstanceStatus deploymentId Created
            errorF "Deployment config is not set"
            pure ()
          (Just deployConfig) -> do
            _ <- generateAndDeployTransaction Deploy deploymentId deployConfig
            pure ()

destroyInstance :: Envelope -> Text -> AppT ()
destroyInstance env deploymentId = do
  let errorF = defaultErrorFallback deploymentId env
  deploymentEnv <- asks $ getEnvFor DeploymentService
  instance'' <- withTokenVariable $ \t -> do
    defaultRetryClient deploymentEnv $ D.getDeploymentInstance deploymentId (BearerWrapper t)
  instance' <- unpackError instance'' errorF
  case instance' of
    Nothing -> pure ()
    (Just (DeploymentInstance { .. })) -> do
      _ <- setDeploymentInstanceStatus deploymentId Destroying
      case instanceDeployConfig of
        Nothing -> do
          -- #TODO: log
          _ <- setDeploymentInstanceStatus deploymentId Created
          errorF "Deployment config is not set"
          deleteRes <- withTokenVariable $ \t -> do
            defaultRetryClient deploymentEnv $ D.deleteDeploymentInstance deploymentId (BearerWrapper t)
          _ <- unpackError deleteRes errorF
          pure ()
        (Just deployConfig) -> do
          deployed <- generateAndDeployTransaction Destroy deploymentId deployConfig
          when deployed $ do
            deleteRes <- withTokenVariable $ \t -> do
              defaultRetryClient deploymentEnv $ D.deleteDeploymentInstance deploymentId (BearerWrapper t)
            _ <- unpackError deleteRes errorF
            pure ()
