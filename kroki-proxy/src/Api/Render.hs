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
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TypeOperators       #-}
module Api.Render
  ( renderServer
  , RenderAPI
  ) where

import           Api
import           Api.Keycloak.Models
import           Api.Keycloak.Token
import           Api.Keycloak.Utils
import           Api.Kroki
import           Api.Utils
import           Config
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import           Data.Functor                    ((<&>))
import           Data.List                       (nub)
import qualified Data.Map                        as M
import           Data.Maybe
import           Data.Text                       (Text)
import qualified Data.Text                       as T
import           Database.Persist
import qualified Deployment.Client               as C
import           Deployment.Models.Deployment
import           Kroki.Schema
import           Models.JSONError
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.VM
import           Redis.Common
import           Servant
import           Service.Environment

renderServer :: ServerT RenderAPI AppT
renderServer = renderDeploymentTemplate

filterLetters = ['a'..'z'] <> ['A'..'Z'] <> ['0'..'9']

generateNetworkLink :: M.Map String String -> Text -> Int -> ConfigVMNetwork -> Text
generateNetworkLink nMap vmName _ (ConfigVMNetwork { .. }) = do
  let netName = T.pack $ fromMaybe configVMNetworkName (M.lookup configVMNetworkName nMap)
  case (configVMInitAdddress, configVMNetworkNumber) of
    (Just DHCP, Just _) -> do
      vmName <> "vm" <> " -- " <> T.filter (`elem` filterLetters) netName <> "net[label=\"dhcp\"]"
    (Just (Manual ip), Just _) -> do
      vmName <> "vm" <> " -- " <> T.filter (`elem` filterLetters) netName <> "net[label=\"" <> T.pack ip <> "\"]"
    _ -> vmName <> "vm" <> " -- " <> T.filter (`elem` filterLetters) netName <> "net"
--generateNetworkLink nMap vmName _ (ConfigVMNetwork { .. }) = do
--  let netName = T.pack $ fromMaybe configVMNetworkName (M.lookup configVMNetworkName nMap)
--  case (configVMInitAdddress, configVMNetworkNumber) of
--    (Just DHCP, Just _) -> do
--      netName <> "-net" <> " -- " <> vmName <> "-vm: dhcp"
--    (Just (Manual ip), Just _) -> do
--      netName <> "-net" <> " -- " <> vmName <> "-vm: " <> T.pack ip
--    _ -> netName <> "-net" <> " -- " <> vmName <> "-vm"

renderDeploymentTemplate :: Text -> BearerWrapper -> AppT Text
renderDeploymentTemplate did (BearerWrapper token) = let

  vms' :: M.Map String String -> M.Map Text Text -> [ConfigVM] -> Text
  vms' nmap dmap = helper "" where
    helper :: Text -> [ConfigVM] -> Text
    helper acc [] = acc
    helper acc (vm:vms) = do
      let screenedName = T.filter (`elem` filterLetters) $ T.pack $ configVMName vm
      let name = T.pack $ configVMName vm
      if T.length screenedName == 0 then helper acc vms else do
        case M.lookup name dmap of
          (Just displayValue) -> do
            let vmDef = "\n" <> screenedName <> "vm" <> "[label=\"" <> name <> "\",URL=\"/vnc/" <> displayValue <> "\",shape=\"hexagon\",fontcolor=\"blue\"]\n"
            let vmNetAmount = (length . fromMaybe [] . configVMNetworks) vm
            let vmNetArr = fromMaybe [] $ configVMNetworks vm
            let netDef = T.intercalate "\n" $ map (generateNetworkLink nmap screenedName vmNetAmount) vmNetArr
            helper (acc <> vmDef <> netDef) vms
          Nothing -> do
            let vmDef = "\n" <> screenedName <> "vm" <> "[label=\"" <> name <> "\",shape=\"hexagon\"]\n"
            let vmNetAmount = (length . configVMNetworks) vm
            let vmNetArr = fromMaybe [] $ configVMNetworks vm
            let netDef = T.intercalate "\n" $ map (generateNetworkLink nmap screenedName vmNetAmount) vmNetArr
            helper (acc <> vmDef <> netDef) vms

  f :: AppT (Maybe Text)
  f = do
    deploymentEnv <- asks $ getEnvFor DeploymentService
    (DeploymentInstance { .. }) <- withTokenVariable'' $ \(t :: Text) -> runClientApp deploymentEnv $ C.getDeploymentInstance did (BearerWrapper t)
    case instanceDeployConfig of
      Nothing -> sendJSONError err400 (JSONError "notDeployed" "instanceIsNotActive" Null)
      (Just (DeployConfig { deployVMs = vms,.. })) -> do
        let ~(Just netMap) = instanceNetworkMap
        let reverseNetMap = (M.fromList . map (\(k, v) -> (v, k)) . M.toList) netMap
        let allNetworks = map (\x -> T.pack $ fromMaybe x (M.lookup x reverseNetMap)) $ nub $ foldMap (map configVMNetworkName . fromMaybe [] . configVMNetworks) vms
        let config :: Text = "graph{\nlayout=\"neato\"\noverlap=\"vpsc\"\nnode[fontsize=\"20\"]\nbeautify=true\nsplines=curved\nratio=0.6\ndefaultdist=10\n" <>
              T.intercalate "\n" (map (\x -> T.filter (`elem` filterLetters) x <> "net[label=\"" <> x <> "\"]") allNetworks) <>
              vms' reverseNetMap instanceVMLinks vms <> "\n}"
        krokiEnv <- asks krokiEnv
        $(logDebug) $ "Rendering schema: " <> config
        resp <- runClientApp krokiEnv $ renderGraphViz (DiagramRequest config)
        case resp of
          (Left e) -> do
            $(logError) $ "Render error: " <> (T.pack . show) e
            sendJSONError err400 (JSONError "renderError" "Failed to render graph" Null)
          (Right r) -> (pure . pure) r
  in do
  r <- getOrCacheJsonValue (Just 30) (T.unpack did <> "-schema") f
  case r of
   (Left _) -> sendJSONError err400 (JSONError "renderError" "Failed to render graph" Null)
   (Right v) -> pure v
