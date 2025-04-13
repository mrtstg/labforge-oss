{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeOperators #-}
module Api.Proxmox.Client 
  ( getVersion
  , getVMConfig
  , getNodeVMs
  , getNodeVMsMap
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

api :: Proxy ProxmoxAPI
api = Proxy

getVersion :<|> getVMConfig :<|> getNodeVMs = client api

getNodeVMsMap :: Text -> Maybe Text -> ClientM (M.Map Int ProxmoxVM)
getNodeVMsMap node token = getNodeVMs node token >>= f where
  f :: ProxmoxResponse [ProxmoxVM] -> ClientM (M.Map Int ProxmoxVM)
  f (ProxmoxResponse vms) = (pure . M.fromList) $ map (\x -> (vmID x, x)) vms
