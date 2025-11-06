{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
module Handler.Power (jobservicePower) where

import           Api.BaseUrl
import           Api.Keycloak.Models
import           Api.Keycloak.Token
import           Api.Retry
import           Config
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Maybe
import           Data.Text                           (Text)
import qualified Data.Text                           as T
import qualified Deployment.Client                   as D
import           Deployment.Models.Deployment
import           Handler.Utils
import           Network.AMQP
import qualified Proxmox.Client                      as P
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.Deploy
import           Proxmox.Deploy.Models.Config.VM
import           Proxmox.Deploy.Models.Transaction
import           Proxmox.Deploy.Ssl
import           Proxmox.Deploy.Transaction
import           Proxmox.Deploy.Types
import           Proxmox.Models
import           Proxmox.Models.Snapshot
import           Proxmox.Models.Storage
import qualified Proxmox.Retry                       as R
import           Proxmox.Schema
import           Service.Environment

defaultErrorFallback :: Text -> Envelope -> String -> AppT (Maybe a)
defaultErrorFallback deploymentId env err = do
  $(logError) $ "[" <> deploymentId <> "]" <> T.pack err
  _ <- setDeploymentInstanceStatus deploymentId Failed
  liftIO $ ackEnv env
  pure Nothing

jobservicePower :: Envelope -> Text -> Bool -> AppT ()
jobservicePower env deploymentId powerOn = do
  let errorF = defaultErrorFallback deploymentId env
  deploymentEnv <- asks $ getEnvFor DeploymentService
  instance'' <- withTokenVariable $ \t -> do
    defaultRetryClient deploymentEnv $ D.getDeploymentInstance deploymentId (BearerWrapper t)
  instance' <- unpackError instance'' errorF
  case instance' of
    Nothing                            -> pure ()
    (Just (DeploymentInstance { .. })) -> do
      case instanceDeployConfig of
        Nothing -> do
          liftIO $ ackEnv env
          pure ()
        (Just deployConfig@(DeployConfig { deployParameters = DeployParams { .. }, .. })) -> do
          let f = if powerOn then P.startVM else P.stopVM
          mgr <- liftIO $ createProxmoxManager deployConfig
          url' <- liftIO $ tryParseUrl (T.unpack deployUrl)
          case url' of
            (Left _) -> do
              liftIO $ ackEnv env
              pure ()
            (Right url) -> do
              let state = ProxmoxState url mgr
              forM_ deployVMs $ \vm -> do
                let vmId = fromMaybe (-1) $ configVMID vm
                _ <- R.defaultRetryClient' state (f deployNodeName vmId)
                $(logInfo) $ "Turned " <> (if powerOn then "on " else "off ") <> (T.pack . show) vmId
