{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
module Utils where

import           Auth
import           Config
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Functor                        ((<&>))
import           Data.Map                            (Map)
import qualified Data.Map                            as M
import           Data.Maybe
import           Data.Text                           (Text)
import qualified Data.Text                           as T
import           Database
import           Database.Persist
import           Models.JSONError
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.Deploy
import           Proxmox.Deploy.Models.Config.VM
import           Proxmox.Models.VM
import           Redis.Common

matchSnapshotRequirements :: String -> Bool
matchSnapshotRequirements "" = False
matchSnapshotRequirements s | length s > 30 = False
                            | length s < 3 = False
                            | otherwise = case s of
  ('_':_) -> False
  (fC:otherSyms) -> fC `elem` ['a'..'z'] ++ ['A'..'Z'] && all (`elem` ['a'..'z'] ++ ['A'..'Z'] ++ ['0'..'9'] ++ ['_']) otherSyms

suggestNetworkBridges :: [Map String String] -> M.Map String String -> Map String String
suggestNetworkBridges l namesMap = helper M.empty l where
  helper :: Map String String -> [Map String String] -> Map String String
  helper acc [] = acc
  helper acc (device:devices) = do
    case M.lookup "bridge" device of
      Nothing -> helper acc devices
      (Just bridgeValue) -> do
        let newBridge = fromMaybe bridgeValue (M.lookup bridgeValue namesMap)
        case filter (\v -> v /= bridgeValue && (length . filter (== ':')) v >= 5) (map snd (M.toList device)) of
          []      -> helper acc devices
          (mac:_) -> helper (M.insert mac newBridge acc) devices

findVMByPort :: Text -> AppT (Maybe (ConfigVM, DeploymentInstanceData))
findVMByPort port = do
  case splitVmPort port of
    Nothing -> pure Nothing
    Just (node, display) -> do
      relatedAllocations <- runDB $ selectList [ UsedDisplayNum ==. display, UsedDisplayNodeName ==. node ] []
      relatedInstances <- runDB $ selectFirst
        [ DeploymentInstanceDataId <-. map (usedDisplayUsedBy . entityVal) relatedAllocations
        , DeploymentInstanceDataDeployConfig !=. Nothing ] []
      case relatedInstances of
        Nothing -> do
          $(logWarn) "No related instances found!"
          pure Nothing
        Just (Entity _ d@(DeploymentInstanceData { .. })) -> do
          let usedVMName = filter (\vm -> configVMDisplay vm == Just display) (deployVMs $ fromJust deploymentInstanceDataDeployConfig)
          case usedVMName of
            [] -> do
              $(logWarn) $ "Couldnt find VM with display " <> (T.pack . show) display
              pure Nothing
            (vm:_) -> do
              (pure . pure) (vm, d)

iterLetters :: Int -> [String]
iterLetters 1 = map (:[]) ['a'..'z']
iterLetters n = do
  s <- iterLetters 1
  v <- iterLetters (n - 1)
  pure $ s <> v
