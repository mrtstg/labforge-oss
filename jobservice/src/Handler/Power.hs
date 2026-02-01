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
  pure Nothing

jobservicePower :: Envelope -> Text -> Bool -> Text -> AppT ()
jobservicePower env deploymentId powerOn mask = do
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
          pure ()
        (Just deployConfig@(DeployConfig { deployParameters = DeployParams { .. }, .. })) -> do
          let f = if powerOn then P.startVM else P.stopVM
          mgr <- liftIO $ createProxmoxManager deployConfig
          url' <- liftIO $ tryParseUrl (T.unpack deployUrl)
          case url' of
            (Left _) -> do
              pure ()
            (Right url) -> do
              let state = ProxmoxState url mgr
              let vmNames = map (T.pack . configVMName) deployVMs
              forM_ (filter (createMaskFunction vmNames mask) deployVMs) $ \vm -> do
                let vmId = fromMaybe (-1) $ configVMID vm
                _ <- R.defaultRetryClient' state (f deployNodeName vmId)
                $(logInfo) $ "Turned " <> (if powerOn then "on " else "off ") <> (T.pack . show) vmId
