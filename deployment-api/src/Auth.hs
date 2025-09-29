{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
module Auth where

import           Config
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Functor                        ((<&>))
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
import           Text.Read                           (readMaybe)

splitVmPort :: Text -> Maybe (Text, Int)
splitVmPort portV = do
  case T.splitOn "-" portV of
    [] -> Nothing
    [_] -> Nothing
    lst -> readMaybe (T.unpack . last $ lst) >>= \x -> Just (T.intercalate "-" (init lst), x)

isUserAccessedVMPort :: Text -> Text -> AppT Bool
isUserAccessedVMPort userId vmPort = let
  f :: AppT Bool
  f = do
    case splitVmPort vmPort of
      Nothing -> pure False
      (Just (nodeName, display)) -> do
        $(logDebug) $ "Checking access from " <> userId <> " to " <> nodeName <> ", " <> (T.pack . show) display
        relatedAllocations <- runDB $ selectList [ UsedDisplayNum ==. display, UsedDisplayNodeName ==. nodeName ] []
        relatedInstances <- runDB $ selectFirst
          [ DeploymentInstanceDataId <-. map (usedDisplayUsedBy . entityVal) relatedAllocations
          , DeploymentInstanceDataDeployConfig !=. Nothing ] []
        case relatedInstances of
          Nothing -> do
            $(logWarn) "No related instances found!"
            pure False
          Just (Entity _ DeploymentInstanceData { .. }) -> do
            let usedVMName = filter (\vm -> configVMDisplay vm == Just display) (deployVMs $ fromJust deploymentInstanceDataDeployConfig)
            case usedVMName of
              [] -> do
                $(logWarn) $ "Couldnt find VM with display " <> (T.pack . show) display
                pure False
              (vm:[]) -> do
                ~(Just (DeploymentTemplateData { .. })) <- runDB $ get deploymentInstanceDataParent
                if userId == deploymentTemplateDataOwnerId then $(logDebug) "Admin access. Allowed." >> pure True else do
                  if userId /= deploymentInstanceDataOwnerId then $(logDebug) "Not admin and not owner" >> pure False else
                    if T.pack (configVMName vm) `elem` deploymentTemplateDataAvailableVMs then $(logDebug) "Stand owner to available VM. Allowed." >> pure True else
                      $(logDebug) "Stand owner to not available VM. Not allowed." >> pure False
              _manyVMs -> do
                $(logError) $ "There is several VM with same display!"
                pure False
      in do
        ~(Right v) <- getOrCacheJsonValue (Just 10) (T.unpack $ userId <> vmPort) (f <&> Just)
        pure v
