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
import Api.Proxmox.Models.VM (ProxmoxVM, ProxmoxVMStatus, ProxmoxVMStatusWrapper, ProxmoxVMDeleteRequest)
import Api.Proxmox.Models.VMConfig (ProxmoxVMConfig)
import Api.Proxmox.Models.Network (ProxmoxNetwork, ProxmoxNetworkType, ProxmoxNetworkFilter)
import Control.Monad.Trans.Reader
import Control.Monad.IO.Class
import Network.HTTP.Conduit
import Servant.Client
import Api.Proxmox.Models.SDNZone
import Api.Proxmox.Models.SDNNetwork
import Api.Proxmox.Models.Node
import Api.Proxmox.Models.VMClone

data ProxmoxState = ProxmoxState BaseUrl Manager

type ProxmoxM m = ReaderT ProxmoxState IO m
type NodeNameCapture = Capture "nodename" Text
type VMIDCapture = Capture "vmid" Int

type ProxmoxAPI = "version" :> Get '[JSON] (ProxmoxResponse ProxmoxVersion)
  :<|> "cluster" :> "sdn" :> "zones" :> Get '[JSON] (ProxmoxResponse [ProxmoxSDNZone])
  :<|> "cluster" :> "sdn" :> "vnets" :> Get '[JSON] (ProxmoxResponse [ProxmoxSDNNetwork])
  :<|> "cluster" :> "sdn" :> "vnets" :> ReqBody '[JSON] ProxmoxSDNNetworkCreate :> Post '[JSON] (ProxmoxResponse ())
  :<|> "cluster" :> "sdn" :> Put '[JSON] (ProxmoxResponse String)
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "config" :> Get '[JSON] (ProxmoxResponse (Maybe ProxmoxVMConfig))
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> Get '[JSON] (ProxmoxResponse [ProxmoxVM])
  :<|> "nodes" :> NodeNameCapture :> "network" :> QueryParam "type" ProxmoxNetworkFilter :> Get '[JSON] (ProxmoxResponse [ProxmoxNetwork])
  :<|> "nodes" :> Get '[JSON] (ProxmoxResponse [ProxmoxNode])
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "status" :> "start" :> Post '[JSON] (ProxmoxResponse ())
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "status" :> "stop" :> Post '[JSON] (ProxmoxResponse ())
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "status" :> "current" :> Get '[JSON] (ProxmoxResponse ProxmoxVMStatusWrapper)
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> QueryParam "destroy-unreferenced-disks" NumericBoolWrapper :> QueryParam "purge" NumericBoolWrapper :> QueryParam "skiplock" NumericBoolWrapper :> Delete '[JSON] (ProxmoxResponse String)
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "clone" :> ReqBody '[JSON] ProxmoxVMCloneParams :> Post '[JSON] (ProxmoxResponse String)
  :<|> "cluster" :> "sdn" :> "vnets" :> Capture "vnet" Text :> Delete '[JSON] ()

runProxmoxState :: ProxmoxState -> ProxmoxM a -> IO a
runProxmoxState = flip runReaderT

runProxmoxClient :: ClientM a -> ProxmoxM (Either ClientError a)
runProxmoxClient m = do
  ProxmoxState url manager' <- ask
  liftIO $ runClientM m (mkClientEnv manager' url)

runProxmoxClient' :: ProxmoxState -> ClientM a -> IO (Either ClientError a)
runProxmoxClient' state = runProxmoxState state . runProxmoxClient
