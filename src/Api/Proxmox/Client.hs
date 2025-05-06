{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeOperators #-}
module Api.Proxmox.Client 
  ( getVersion
  , getVMConfig
  , getNodeVMs
  , getNodeVMsMap
  , getNodeNetworks
  , getBridgeNodeNetworks
  , getSDNZones
  ) where

import Data.Text (Text)
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

api :: Proxy ProxmoxAPI
api = Proxy

getVersion 
  :<|> getSDNZones
  :<|> getVMConfig 
  :<|> getNodeVMs 
  :<|> getNodeNetworks = client api

getNodeVMsMap :: Text -> ClientM (M.Map Int ProxmoxVM)
getNodeVMsMap node = getNodeVMs node >>= f where
  f :: ProxmoxResponse [ProxmoxVM] -> ClientM (M.Map Int ProxmoxVM)
  f (ProxmoxResponse vms) = (pure . M.fromList) $ map (\x -> (vmID x, x)) vms

-- shortcut for getting networks for plugging vms into
getBridgeNodeNetworks :: Text -> ClientM [ProxmoxNetwork]
getBridgeNodeNetworks node = do
  (ProxmoxResponse nets) <- getNodeNetworks node (Just AnyBridge)
  return nets
