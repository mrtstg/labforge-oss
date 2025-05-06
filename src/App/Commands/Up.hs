module App.Commands.Up 
  ( runUpCommand
  ) where

import Data.Models.Config.Template
import Deploy.Template
import Deploy.VM
import Api.Proxmox
import Api.Proxmox.Models.Version
import Data.Models.Config.VM
import qualified Api.Proxmox.Client as C
import Control.Exception
import System.Exit
import Data.Models.Config.Deploy
import Data.Models.Config
import Api.Proxmox.Models
import Data.List (intercalate)
import Data.Text (Text)
import Data.Map (Map)
import Api.Proxmox.Client
import Api.Proxmox.Models.Network
import Api.Proxmox.Models.VM
import System.Log.Logger
import Data.Models.Config.Network
import Deploy.Network

loggerName = "ProxmoxCompose.Main"

getNodeVMs' :: ProxmoxState -> Text -> IO (Map Int ProxmoxVM)
getNodeVMs' proxmoxState nodeName = do
  infoM loggerName "Retrieving node virtual machines info..."
  vmMapRes <- runProxmoxClient' proxmoxState $ C.getNodeVMsMap nodeName
  case vmMapRes of
    (Left err) -> do
      errorM loggerName ("Failed to get node VMs: " <> displayException err)
      exitWith (ExitFailure 1)
    (Right vmMap) -> return vmMap

checkTemplates :: Map Int ProxmoxVM -> [ConfigTemplate] -> [ConfigVM] -> IO ()
checkTemplates vmMap templates vms = do
  case vmIDPresent vmMap (map configTemplateID templates) of
    (Left missingIDs) -> do
      let missingTemplatesData = filter ((`elem` missingIDs) . configTemplateID) templates
      errorM loggerName $ "Following templates was not found: " <> intercalate ", " (map configTemplateName missingTemplatesData)
      exitWith (ExitFailure 1)
    (Right _) -> do
      infoM loggerName "All templates are present!"
      case validateVMsData templates vms of
        (Left err) -> do
          errorM loggerName (show err)
          exitWith (ExitFailure 1)
        _ -> return ()

getBridges' :: ProxmoxState -> Text -> IO [ProxmoxNetwork]
getBridges' proxmoxState nodeName = do
  infoM loggerName "Getting node bridges..."
  res <- runProxmoxClient' proxmoxState $ getBridgeNodeNetworks nodeName
  case res of
    (Left e) -> do
      errorM loggerName $ "Failed to get node bridges: " <> displayException e
      exitWith (ExitFailure 1)
    (Right networks) -> return networks

validateNetworks' :: [ConfigNetwork] -> [ProxmoxNetwork] -> IO ()
validateNetworks' cfg pve = do
  case validateConfigNetworks cfg pve of
    (Left e) -> do
      errorM loggerName (show e)
      exitWith (ExitFailure 1)
    (Right _) -> pure ()

runUpCommand :: ProxmoxState -> DeployConfig -> IO ()
runUpCommand proxmoxState deployConfig@(DeployConfig 
    { deployParameters = DeployParams { deployNodeName = nodeName }
    , deployTemplates = templates
    , deployVMs = vms
    , deployNetworks = networks
    }) = do
    vmMap <- getNodeVMs' proxmoxState nodeName
    () <- checkTemplates vmMap templates vms
    bridges <- getBridges' proxmoxState nodeName
    () <- validateNetworks' networks bridges

    -- TODO: delete
    infoM loggerName (show deployConfig)
    exitSuccess
