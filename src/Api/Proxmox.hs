{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
module Api.Proxmox 
  ( ProxmoxAPI
  , ProxmoxState(..)
  , ProxmoxM
  , runProxmoxState
  , runProxmoxClient
  , runProxmoxClient'
  ) where

import Data.Text
import Servant.API
import Api.Proxmox.Models.Version
import Api.Proxmox.Models
import Api.Proxmox.Models.VM (ProxmoxVM)
import Api.Proxmox.Models.VMConfig (ProxmoxVMConfig)
import Api.Proxmox.Models.Network (ProxmoxNetwork, ProxmoxNetworkType, ProxmoxNetworkFilter)
import Control.Monad.Trans.Reader
import Control.Monad.IO.Class
import Network.HTTP.Conduit
import Servant.Client
import Api.Proxmox.Models.SDNZone
import Api.Proxmox.Models.SDNNetwork

data ProxmoxState = ProxmoxState BaseUrl Manager

type ProxmoxM m = ReaderT ProxmoxState IO m
type NodeNameCapture = Capture "nodename" Text

type ProxmoxAPI = "version" :> Get '[JSON] (ProxmoxResponse ProxmoxVersion)
  :<|> "cluster" :> "sdn" :> "zones" :> Get '[JSON] (ProxmoxResponse [ProxmoxSDNZone])
  :<|> "cluster" :> "sdn" :> "vnets" :> Get '[JSON] (ProxmoxResponse [ProxmoxSDNNetwork])
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> Capture "vmid" Integer :> "config" :> Get '[JSON] (ProxmoxResponse (Maybe ProxmoxVMConfig))
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> Get '[JSON] (ProxmoxResponse [ProxmoxVM])
  :<|> "nodes" :> NodeNameCapture :> "network" :> QueryParam "type" ProxmoxNetworkFilter :> Get '[JSON] (ProxmoxResponse [ProxmoxNetwork])

runProxmoxState :: ProxmoxState -> ProxmoxM a -> IO a
runProxmoxState = flip runReaderT

runProxmoxClient :: ClientM a -> ProxmoxM (Either ClientError a)
runProxmoxClient m = do
  ProxmoxState url manager' <- ask
  liftIO $ runClientM m (mkClientEnv manager' url)

runProxmoxClient' :: ProxmoxState -> ClientM a -> IO (Either ClientError a)
runProxmoxClient' state = runProxmoxState state . runProxmoxClient
