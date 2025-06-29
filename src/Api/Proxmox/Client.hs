{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE RecordWildCards #-}
module Api.Proxmox.Client 
  ( getVersion
  , getVMConfig
  , getNodeVMs
  , getNodeVMsMap
  , getNodeNetworks
  , getBridgeNodeNetworks
  , getSDNZones
  , getSDNNetworks
  , getNodes
  , getActiveNodes
  , getActiveNodesVMMap
  , startVM
  , stopVM
  , getVMPower
  ) where

import Data.Text (Text, pack)
import qualified Data.Map as M
import Data.Aeson
import Data.Proxy
import GHC.Generics
import Network.HTTP.Client (newManager, defaultManagerSettings)
import Servant.API
import Servant.Client
import Api.Proxmox
import qualified Servant.Client.Streaming as S
import Api.Proxmox.Models.VM (ProxmoxVM(..))
import Api.Proxmox.Models (ProxmoxResponse(..))
import Api.Proxmox.Models.Network
import Api.Proxmox.Models.SDNNetwork
import Api.Proxmox.Models.Node

api :: Proxy ProxmoxAPI
api = Proxy

getVersion 
  :<|> getSDNZones
  :<|> getSDNNetworks
  :<|> createSDNNetwork
  :<|> applySDNSettings
  :<|> getVMConfig 
  :<|> getNodeVMs 
  :<|> getNodeNetworks
  :<|> getNodes 
  :<|> startVM
  :<|> stopVM
  :<|> getVMPower = client api

getActiveNodesVMMap :: ClientM (M.Map Int ProxmoxVM)
getActiveNodesVMMap = do
  nodes <- getActiveNodes
  nodeMaps <- traverse (getNodeVMsMap . pack . nodeName) nodes
  return $ foldr (M.unionWith const) M.empty nodeMaps

getNodeVMsMap :: Text -> ClientM (M.Map Int ProxmoxVM)
getNodeVMsMap node = getNodeVMs node >>= f where
  f :: ProxmoxResponse [ProxmoxVM] -> ClientM (M.Map Int ProxmoxVM)
  f (ProxmoxResponse vms) = (pure . M.fromList) $ map (\x -> (vmID x, x)) vms

-- shortcut for getting networks for plugging vms into
getBridgeNodeNetworks :: Text -> ClientM [ProxmoxNetwork]
getBridgeNodeNetworks node = do
  (ProxmoxResponse nets) <- getNodeNetworks node (Just AnyBridge)
  return nets

getActiveNodes :: ClientM [ProxmoxNode]
getActiveNodes = do
  (ProxmoxResponse nodes) <- getNodes
  return $ filter ((== NodeOnline) . nodeStatus) nodes
