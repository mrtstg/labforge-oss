module App.Commands.Up 
  ( runUpCommand
  ) where

import Data.Models.Config.Template
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
import Utils
import Api.Proxmox.Models.SDNNetwork
import Api.Proxmox.Models.SDNZone
import Deploy.Transaction

loggerName = "ProxmoxCompose.Main"

getActiveNodesVMMap' :: ProxmoxState -> IO (Map Int ProxmoxVM)
getActiveNodesVMMap' proxmoxState = do
  infoM loggerName "Retrieving node virtual machines info..."
  commonErrorStdoutHandler loggerName (runProxmoxClient' proxmoxState C.getActiveNodesVMMap) (\err -> "Failed to get node VMs: " <> displayException err)

getBridges' :: ProxmoxState -> Text -> IO [ProxmoxNetwork]
getBridges' proxmoxState nodeName = do
  infoM loggerName "Getting node bridges..."
  commonErrorStdoutHandler loggerName (runProxmoxClient' proxmoxState $ getBridgeNodeNetworks nodeName) (\e -> "Failed to get node bridges: " <> displayException e)

getSDNNetworks' :: ProxmoxState -> IO [ProxmoxSDNNetwork]
getSDNNetworks' proxmoxState = do
  (ProxmoxResponse networks) <- commonErrorStdoutHandler loggerName (runProxmoxClient' proxmoxState getSDNNetworks) (\e -> "Failed to get SDN networks: " <> displayException e)
  return networks

getSDNZones' :: ProxmoxState -> IO [ProxmoxSDNZone]
getSDNZones' proxmoxState = do
  (ProxmoxResponse zones) <- commonErrorStdoutHandler loggerName (runProxmoxClient' proxmoxState getSDNZones) (\e -> "Failed to get SDN zones: " <> displayException e)
  return zones  

runUpCommand :: ProxmoxState -> DeployConfig -> IO ()
runUpCommand proxmoxState deployConfig@(DeployConfig 
    { deployParameters = DeployParams { deployNodeName = nodeName }
    , deployTemplates = templates
    , deployVMs = vms
    , deployNetworks = networks
    }) = do
    () <- commonErrorStdoutHandler loggerName (pure $ validateVMsData templates vms) show
    vmMap <- getActiveNodesVMMap' proxmoxState
    bridges <- getBridges' proxmoxState nodeName
    sdnNetworks <- getSDNNetworks' proxmoxState
    sdnZones <- getSDNZones' proxmoxState

    let stages = planTransactionStages deployConfig
    let transactionRes = planTransactionActions stages deployConfig bridges sdnZones sdnNetworks vmMap
    case transactionRes of
      (Left e) -> do
        errorM loggerName (show e)
      (Right actions) -> do
        mapM_ print actions
    exitSuccess
