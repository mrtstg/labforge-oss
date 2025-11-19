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
module Handler.Snapshot
  ( jobserviceSnapshot
  , jobserviceRollback
  ) where

import           Api.Keycloak.Models
import           Api.Keycloak.Token
import           Api.Retry
import           Config
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Text                         (Text)
import qualified Data.Text                         as T
import qualified Deployment.Client                 as D
import           Deployment.Models.Deployment
import           Handler.Utils
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Transaction
import           Proxmox.Models.Snapshot
import           Service.Environment

defaultErrorFallback :: Text  -> String -> AppT (Maybe a)
defaultErrorFallback deploymentId err = do
  $(logError) $ "[" <> deploymentId <> "]" <> T.pack err
  _ <- setDeploymentInstanceStatus deploymentId Failed
  pure Nothing

jobserviceRollback :: Text -> Text -> AppT ()
jobserviceRollback deploymentId snapName = do
  $(logInfo) $ "Rollback of instance " <> (T.pack . show) deploymentId
  deploymentEnv <- asks $ getEnvFor DeploymentService
  instance'' <- withTokenVariable $ \t -> do
    defaultRetryClient deploymentEnv $ D.getDeploymentInstance deploymentId (BearerWrapper t)
  instance' <- unpackError instance'' (defaultErrorFallback deploymentId)
  case instance' of
    Nothing -> pure ()
    (Just (DeploymentInstance { .. })) -> do
      case instanceDeployConfig of
        Nothing -> do
          $(logError) $ "Deployment config is not set!"
          -- logInstance "Deployment config is not set!"
          _ <- setDeploymentInstanceStatus deploymentId Failed
          pure ()
        (Just deployConfig@(DeployConfig { deployVMs = vms })) -> do
          _ <- deployTransaction (map (`VMRollbacked` T.unpack snapName) vms) deploymentId deployConfig
          pure ()

jobserviceSnapshot :: Text -> Text -> Bool -> AppT ()
jobserviceSnapshot deploymentId snapName delete = do
  $(logInfo) $ "Snapping instance " <> (T.pack . show) deploymentId
  deploymentEnv <- asks $ getEnvFor DeploymentService
  instance'' <- withTokenVariable $ \t -> do
    defaultRetryClient deploymentEnv $ D.getDeploymentInstance deploymentId (BearerWrapper t)
  instance' <- unpackError instance'' (defaultErrorFallback deploymentId)
  case instance' of
    Nothing -> pure ()
    (Just (DeploymentInstance { .. })) -> do
      case instanceDeployConfig of
        Nothing -> do
          $(logError) $ "Deployment config is not set!"
          --logInstance "Deployment config is not set!"
          _ <- setDeploymentInstanceStatus deploymentId Failed
          pure ()
        (Just deployConfig@(DeployConfig { deployVMs = vms })) -> do
          _ <- deployTransaction (map ((\x -> if delete then flip SnapshotNotExists x else flip SnapshotExists x) (ProxmoxSnapshotCreate {snapshotCreateStateful=Just True, snapshotCreateName=snapName, snapshotCreateDesc=Nothing})) vms) deploymentId deployConfig
          pure ()
