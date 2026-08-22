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
module Auth where

import           Config
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Functor                    ((<&>))
import           Data.List                       (find)
import           Data.Maybe
import           Data.Text                       (Text)
import qualified Data.Text                       as T
import           Database
import           Database.Persist
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.VM
import           Redis.Common
import           Text.Read                       (readMaybe)

splitVmPort :: Text -> Maybe Int
splitVmPort = readMaybe . T.unpack

findInstanceByVMPort :: Text -> AppT (Maybe (Entity DeploymentInstanceData, ConfigVM))
findInstanceByVMPort vmPort = do
  case splitVmPort vmPort of
    Nothing -> pure Nothing
    (Just vmid) -> do
      allocations <- runDB $ selectList [UsedVMIDNum ==. vmid] []
      instances <- runDB $ selectList
        [ DeploymentInstanceDataId <-. map (usedVMIDUsedBy . entityVal) allocations
        , DeploymentInstanceDataDeployConfig !=. Nothing ] []
      let matches = mapMaybe (matchVM vmid) instances
      case matches of
        [] -> $(logWarn) ("No VM found for " <> vmPort) >> pure Nothing
        [match] -> pure $ Just match
        _ -> $(logError) ("Several VMs found for " <> vmPort) >> pure Nothing
  where
    matchVM :: Int -> Entity DeploymentInstanceData -> Maybe (Entity DeploymentInstanceData, ConfigVM)
    matchVM vmid entity@(Entity _ DeploymentInstanceData { deploymentInstanceDataDeployConfig = Just config }) = do
      vm <- find ((== Just vmid) . configVMID) (deployVMs config)
      pure (entity, vm)
    matchVM _ _ = Nothing

isUserAccessedVMPort :: [Text] -> [Text] -> Text -> Text -> AppT Bool
isUserAccessedVMPort userGroups userRoles userId vmPort = let
  f :: AppT Bool
  f = do
    let deployTemplatesAdmin = "deployment-admin"
    related <- findInstanceByVMPort vmPort
    case related of
      Nothing -> pure False
      Just (Entity _ DeploymentInstanceData { .. }, vm) ->
        if deployTemplatesAdmin `elem` userRoles then pure True else do
          ~(Just (DeploymentTemplateData { .. })) <- runDB $ get deploymentInstanceDataParent
          templateHidden <- runDB $ exists [ DeploymentTemplateHideGroup <-. userGroups, DeploymentTemplateHideDeployment ==. deploymentInstanceDataParent]
          if userId == deploymentTemplateDataOwnerId then $(logDebug) "Admin access. Allowed." >> pure True else do
            if userId /= deploymentInstanceDataOwnerId || templateHidden then $(logDebug) "Not admin and not owner" >> pure False else
              if T.pack (configVMName vm) `elem` deploymentTemplateDataAvailableVMs then $(logDebug) "Stand owner to available VM. Allowed." >> pure True else
                $(logDebug) "Stand owner to not available VM. Not allowed." >> pure False
      in do
        ~(Right v) <- getOrCacheJsonValue (Just 10) (T.unpack $ userId <> vmPort) (f <&> Just)
        pure v
