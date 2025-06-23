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
import Utils
import Api.Proxmox.Models.SDNNetwork

loggerName = "ProxmoxCompose.Main"

getActiveNodesVMMap' :: ProxmoxState -> IO (Map Int ProxmoxVM)
getActiveNodesVMMap' proxmoxState = do
  infoM loggerName "Retrieving node virtual machines info..."
  commonErrorStdoutHandler loggerName (runProxmoxClient' proxmoxState C.getActiveNodesVMMap) (\err -> "Failed to get node VMs: " <> displayException err)

checkTemplates :: Map Int ProxmoxVM -> [ConfigTemplate] -> [ConfigVM] -> IO ()
checkTemplates vmMap templates vms = do
  case vmIDPresent vmMap (map configTemplateID templates) of
    (Left missingIDs) -> do
      let missingTemplatesData = filter ((`elem` missingIDs) . configTemplateID) templates
      errorM loggerName $ "Following templates was not found: " <> intercalate ", " (map configTemplateName missingTemplatesData)
      exitWith (ExitFailure 1)
    (Right _) -> do
      infoM loggerName "All templates are present!"
      commonErrorStdoutHandler' loggerName (pure $ validateVMsData templates vms)

getBridges' :: ProxmoxState -> Text -> IO [ProxmoxNetwork]
getBridges' proxmoxState nodeName = do
  infoM loggerName "Getting node bridges..."
  commonErrorStdoutHandler loggerName (runProxmoxClient' proxmoxState $ getBridgeNodeNetworks nodeName) (\e -> "Failed to get node bridges: " <> displayException e)

validateNetworks' :: [ConfigNetwork] -> [ProxmoxNetwork] -> IO ()
validateNetworks' cfg pve = commonErrorStdoutHandler' loggerName (pure $ validateConfigNetworks cfg pve)

getSDNNetworks' :: ProxmoxState -> IO [ProxmoxSDNNetwork]
getSDNNetworks' proxmoxState = do
  (ProxmoxResponse networks) <- commonErrorStdoutHandler loggerName (runProxmoxClient' proxmoxState getSDNNetworks) (\e -> "Failed to get SDN networks: " <> displayException e)
  return networks

runUpCommand :: ProxmoxState -> DeployConfig -> IO ()
runUpCommand proxmoxState deployConfig@(DeployConfig 
    { deployParameters = DeployParams { deployNodeName = nodeName }
    , deployTemplates = templates
    , deployVMs = vms
    , deployNetworks = networks
    }) = do
    vmMap <- getActiveNodesVMMap' proxmoxState
    print vmMap
    () <- checkTemplates vmMap templates vms
    bridges <- getBridges' proxmoxState nodeName
    () <- validateNetworks' networks bridges
    
    sdnNetworks <- getSDNNetworks' proxmoxState

    -- TODO: delete
    infoM loggerName (show deployConfig)
    exitSuccess
