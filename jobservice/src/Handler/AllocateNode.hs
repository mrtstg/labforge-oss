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
module Handler.AllocateNode (allocateNode) where

import           Api.Keycloak.Models
import           Api.Keycloak.Models.User
import           Api.Keycloak.Token
import           Api.Retry
import           Auth.Client
import qualified Cluster.Client                           as C
import           Cluster.Models.Node
import           Config
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.List                                (nub)
import qualified Data.Map                                 as M
import           Data.Maybe
import qualified Data.Text                                as T
import qualified Deployment.Client                        as D
import           Deployment.Models.Deployment
import           Handler.Utils
import qualified Jobservice.Client                        as J
import           Jobservice.Models
import           Network.AMQP
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.Deploy
import           Proxmox.Deploy.Models.Config.DeployAgent
import           Proxmox.Deploy.Models.Config.Network
import           Proxmox.Deploy.Models.Config.VM
import           Service.Environment
import           Utils.Time

defaultErrorFallback :: JobserviceMessageMeta -> Envelope -> String -> AppT (Maybe a)
defaultErrorFallback m@(JobserviceMessageMeta {deploymentId=deploymentId}) env err = do
  $(logError) $ "[" <> deploymentId <> "]" <> T.pack err
  _ <- setDeploymentInstanceStatus m Failed
  pure Nothing

renameNet :: M.Map String String -> ConfigVM -> ConfigVM
renameNet _ vmData@(TemplatedConfigVM { configVMNetworks = Nothing }) = vmData
renameNet namesMap vmData@(TemplatedConfigVM { configVMNetworks = Just nets }) = vmData { configVMNetworks = Just (map f nets) } where
  f :: ConfigVMNetwork -> ConfigVMNetwork
  f d@(ConfigVMNetwork { configVMNetworkName = n }) = case M.lookup n namesMap of
    Nothing  -> d
    (Just v) -> d { configVMNetworkName = v }

allocateNode :: (Envelope, Message) -> JobserviceMessageMeta -> AppT ()
allocateNode (env, msg) m@(JobserviceMessageMeta { .. }) = do
  let errorF = defaultErrorFallback m env
  deploymentEnv <- asks $ getEnvFor DeploymentService
  deployment'' <- withTokenVariable $ \token -> do
    defaultRetryClientC deploymentEnv (D.getDeploymentInstance deploymentId (BearerWrapper token))
  deployment' <- unpackError deployment'' errorF
  case deployment' of
    Nothing                            -> pure ()
    (Just (DeploymentInstance { .. })) -> do
      if isJust instanceDeployConfig then pure () else do
        $(logInfo) $ "[" <> deploymentId <> "] Got deployment instance"
        authEnv <- asks $ getEnvFor AuthService
        ownerData'' <- withTokenVariable $ \t -> do
          defaultRetryClientC authEnv $ getUserBriefInfo instanceUser (BearerWrapper t)
        ownerData' <- unpackError ownerData'' errorF
        case ownerData' of
          Nothing -> pure ()
          (Just (BriefUser { .. })) -> do
            $(logInfo) $ "[" <> deploymentId <> "] Got user info"
            template'' <- withTokenVariable $ \token -> do
              defaultRetryClientC deploymentEnv (D.getDeploymentTemplate instanceOf (BearerWrapper token))
            template' <- unpackError template'' errorF
            case template' of
              Nothing -> pure ()
              (Just (DeploymentTemplate { .. })) -> do
                $(logInfo) $ "[" <> deploymentId <> "] Got deployment template"
                let vmTags = map T.unpack [templateTitle, fromMaybe "" userFirstName <> " " <> fromMaybe "" userLastName]
                clusterEnv <- asks $ getEnvFor ClusterManager
                nodeRequest'' <- withTokenVariable $ \t -> do
                  defaultRetryClientC clusterEnv $ C.getDeployNode (BearerWrapper t)
                nodeRequest' <- unpackError nodeRequest'' errorF
                case nodeRequest' of
                  Nothing                     -> pure ()
                  (Just (ClusterNode { .. })) -> do
                    $(logInfo) $ "[" <> deploymentId <> "] Allocated node"
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
                    allocateRes'' <- withTokenVariable $ \t -> do
                      defaultRetryClientC deploymentEnv (D.requestDeploymentVMID nodeName deploymentId (Just $ length templateVMs) (BearerWrapper t))
                    allocateRes' <- unpackError allocateRes'' errorF
                    case allocateRes' of
                      Nothing -> pure ()
                      (Just vmids) -> do
                        $(logInfo) $ "[" <> deploymentId <> "] Allocated VMIDs"
                        let sdnNetworksNames = nub . filter (`notElem` templateExistingNetworks) . map (T.pack . configVMNetworkName) $ foldMap (fromMaybe [] . configVMNetworks) templateVMs
                        networkAllocateRes'' <- withTokenVariable $ \t -> do
                          defaultRetryClientC deploymentEnv (D.requestDeploymentNetwork nodeName deploymentId (Just $ length sdnNetworksNames) (BearerWrapper t))
                        networkAllocateRes' <- unpackError networkAllocateRes'' errorF
                        case networkAllocateRes' of
                          Nothing -> pure ()
                          (Just sdnNames) -> do
                            $(logInfo) $ "[" <> deploymentId <> "] Allocated SDN networks"
                            sdnZone <- asks (T.unpack . deploySDNZone)
                            let namesMap = M.mapKeys T.unpack . M.fromList $ zip sdnNetworksNames sdnNames
                            let networks = map (ExistingNetwork . T.unpack) templateExistingNetworks ++ map (\n -> SDNNetwork {configNetworkZone=sdnZone, configNetworkVLANAware=Nothing, configNetworkSubnets=[], configNetworkName=n}) sdnNames
                            let replacedNetworksVM = map (renameNet namesMap) templateVMs
                            displayAllocRes'' <- withTokenVariable $ \t -> do
                              defaultRetryClientC deploymentEnv (D.requestDeploymentDisplay nodeName deploymentId (Just $ length templateVMs) (BearerWrapper t))
                            displayAllocRes' <- unpackError displayAllocRes'' errorF
                            case displayAllocRes' of
                              Nothing -> pure ()
                              (Just vmDisplays) -> do
                                $(logInfo) $ "[" <> deploymentId <> "] Allocated displays"
                                let zippedDisplays = zip replacedNetworksVM vmDisplays
                                let linksMap = M.mapKeys configVMName $ M.map (\d -> T.unpack nodeName <> "-" <> show d) $ M.fromList zippedDisplays
                                let configuredVMs = zipWith (\d v -> v {configVMID = Just d, configVMTags = vmTags}) vmids (map (\ (v, d) -> v {configVMDisplay = Just d}) zippedDisplays)
                                templates'' <- withTokenVariable $ \t -> do
                                  defaultRetryClientC deploymentEnv (D.getTemplatesListByNames (map (T.pack . configVMParentTemplate) configuredVMs) (BearerWrapper t))
                                templates' <- unpackError templates'' errorF
                                case templates' of
                                  Nothing -> pure ()
                                  (Just templates) -> do
                                    $(logInfo) $ "[" <> deploymentId <> "] Got templates list"
                                    let deployConfig = DeployConfig { deployAgent=Just agentConfig
                                      , deployVMs=configuredVMs
                                      , deployNetworks=networks
                                      , deployTemplates=templates
                                      , deployParameters=deployNode
                                      }
                                    let patch = DeploymentPatch {
                                      patchInstanceVMLinks=Just linksMap
                                      , patchInstanceState=Nothing
                                      , patchInstanceNetworkMap=Just namesMap
                                      , patchInstanceDeployConfig=Just deployConfig
                                      }
                                    patchRes <- withTokenVariable $ \t ->
                                      defaultRetryClientC deploymentEnv (D.patchDeploymentInstance deploymentId patch (BearerWrapper t))
                                    p <- unpackError patchRes errorF
                                    case p of
                                      Nothing -> pure ()
                                      _ -> do
                                        jobserviceEnv <- asks $ getEnvFor JobserviceAPI
                                        jobRes <- withTokenVariable $ \t ->
                                          defaultRetryClientC jobserviceEnv (J.insertJobserviceMessage (JobserviceTask (Just m) (JobserviceDeployInstance {})) (BearerWrapper t))
                                        j <- unpackError jobRes errorF
                                        case j of
                                          Nothing -> pure ()
                                          _ -> do
                                            $(logInfo) $ "[" <> deploymentId <> "] Sent new deploy job"
                                            pure ()
allocateNode _ _ = error "Invalid message"
