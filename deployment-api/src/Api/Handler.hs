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

import           Api.Keycloak.Models
import           Api.Keycloak.Models.User
import           Api.Keycloak.Token
import           Api.Keycloak.Utils
import           Auth.Client
import           Config
import           Control.Concurrent.STM
import           Control.Monad.Logger
import           Control.Monad.Reader
import qualified Data.Map                     as M
import           Data.Text                    (Text, pack, unpack)
import           Database
import           Database.Persist
import           Deployment.Models.Deployment
import qualified Jobservice.Client            as J
import           Jobservice.Models
import           Models
import           Proxmox.Retry
import           Service.Environment


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
      mapM_ (\(DeploymentInstanceDataKey t) -> withTokenVariable $ \token -> defaultRetryClient jobserviceEnv $ J.insertJobserviceMessage (JobserviceSnapshot t snapName False mask "") (BearerWrapper token)) existingDeployments
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
      mapM_ (\(DeploymentInstanceDataKey t) -> withTokenVariable $ \token -> defaultRetryClient jobserviceEnv $ J.insertJobserviceMessage (JobserviceSnapshot t snapName True mask "") (BearerWrapper token)) existingDeployments
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
