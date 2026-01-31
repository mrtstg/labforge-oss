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
{-# LANGUAGE NumericUnderscores  #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TupleSections       #-}
module Handler.ImageUsage
  ( cacheUsedImages
  ) where

import           Api
import           Api.Keycloak.Models
import           Api.Keycloak.Models.User
import           Api.Keycloak.Token
import           Api.Keycloak.Utils
import           Api.Retry
import           App.Types
import qualified Auth.Client                     as Auth
import           Auth.Token
import           Config
import           Control.Concurrent
import           Control.Concurrent.STM
import           Control.Concurrent.STM.TVar
import           Control.Monad                   (forever, when)
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8      as LBS
import           Data.Either
import           Data.List                       (nub)
import qualified Data.Map                        as M
import           Data.Maybe
import           Data.Text                       (Text, pack)
import qualified Data.Text                       as T
import           Deployment.Client
import           Deployment.Models.Deployment
import           Handler.AllocateNode
import           Handler.Deployment
import           Handler.Power
import           Handler.Snapshot
import           Jobservice.Models
import           Network.AMQP
import           Pool
import           Proxmox.Deploy.Models.Config.VM
import           Redis.Common
import           Redis.Environment
import           Servant.Client
import           Service.Config
import           Service.Environment
import           System.Environment
import           System.Exit
import           System.Random

getAllTemplates :: AppT (Maybe [DeploymentTemplate])
getAllTemplates = let
  helper :: [DeploymentTemplate] -> Int -> AppT (Maybe [DeploymentTemplate])
  helper acc page = do
    env <- asks $ getEnvFor DeploymentService
    res <- withTokenVariable $ \token -> do
      defaultRetryClientC env (getPagedDeploymentTemplates (Just page) (BearerWrapper token))
    case res of
      (Left _) -> $(logError) "Token issue error" >> pure Nothing
      (Right r) -> do
        case r of
          (Left e) -> do
            $(logError) $ "Client error: " <> (pack . show) e
            pure Nothing
          (Right (PagedResponse { .. })) -> do
            case responseObjects of
              [] -> (pure . Just) acc
              elems -> do
                helper (elems ++ acc) (page + 1)
  in helper [] 1

fillUsedTemplatesMap :: M.Map String [JobserviceImageUsageData] -> [DeploymentTemplate] -> M.Map String [JobserviceImageUsageData]
fillUsedTemplatesMap acc [] = acc
fillUsedTemplatesMap acc (template:templates) = let
  f :: String -> M.Map String [JobserviceImageUsageData] -> M.Map String [JobserviceImageUsageData]
  f imageName m = do
    case M.lookup imageName acc of
      Nothing -> acc
      (Just v) -> M.insert imageName (JobserviceImageUsageData {usedImageDeploymentUserName="", usedImageDeploymentUserId=templateOwner template, usedImageDeploymentName=templateTitle template, usedImageDeploymentId=templateId template}:v) m
  in do
  let images = map configVMParentTemplate . filter isTemplateVM $ templateVMs template
  let nmap = foldr f acc images
  fillUsedTemplatesMap nmap templates

getUsersMap :: [Text] -> AppT (M.Map Text BriefUser)
getUsersMap userIds = do
  authEnv <- asks $ getEnvFor AuthService
  userData' <- withTokenVariable $ \t -> do
     mapM (defaultRetryClientC authEnv . flip Auth.getUserBriefInfo (BearerWrapper t)) userIds
  case userData' of
    (Left e) -> do
      $(logError) $ T.pack e
      pure M.empty
    (Right v) -> do
      pure $ (M.fromList . map ((\e -> (userID e, e)) . fromRight undefined) . filter isRight) v

fillUsers :: M.Map Text BriefUser -> M.Map String [JobserviceImageUsageData] -> M.Map String [JobserviceImageUsageData]
fillUsers usersMap = helper M.empty . M.toList where
  f :: JobserviceImageUsageData -> JobserviceImageUsageData
  f d@(JobserviceImageUsageData { .. }) = case M.lookup usedImageDeploymentUserId usersMap of
    Nothing -> d { usedImageDeploymentUserName = "Неизвестный пользователь" }
    (Just (BriefUser { .. })) -> do
      d { usedImageDeploymentUserName = fromMaybe "-" userFirstName <> " " <> fromMaybe "-" userLastName }

  helper :: M.Map String [JobserviceImageUsageData] -> [(String, [JobserviceImageUsageData])] -> M.Map String [JobserviceImageUsageData]
  helper acc [] = acc
  helper acc ((imageName, arr):arrs) = do
    let narr = map f arr
    helper (M.insert imageName narr acc) arrs

cacheUsedImages :: AppT ()
cacheUsedImages = do
  $(logInfo) "Getting templates"
  tmpls <- getAllTemplates
  case tmpls of
    Nothing -> $(logError) "Failed to get templates"
    (Just d) -> do
      let usedTemplates = nub $ foldMap (map configVMParentTemplate . filter isTemplateVM . templateVMs) d
      let emptyMap = M.fromList . map (, []) $ usedTemplates
      let usageMap = fillUsedTemplatesMap emptyMap d
      let allUsersList = nub $ foldMap (map usedImageDeploymentUserId) $ M.elems usageMap
      usersMap <- getUsersMap allUsersList
      let usageList = M.toList $ fillUsers usersMap usageMap
      forM_ usageList $ \(imageName, usageData) -> do
        cacheValue' (jobserviceUsedImageKey imageName) (LBS.unpack . encode $ usageData) (Just $ 15 * 60)
      cacheValue' jobserviceUsedImagesKey (LBS.unpack . encode $ usedTemplates) (Just $ 15 * 60)
      $(logInfo) "Value updated!"
