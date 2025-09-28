{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}
module Proxmox.Schema
  ( ProxmoxAPI
  , ProxmoxState(..)
  , ProxmoxM
  , runProxmoxState
  , runProxmoxClient
  , runProxmoxClient'
  ) where

import           Control.Monad.IO.Class
import           Control.Monad.Trans.Reader
import           Data.Aeson                 (Value)
import qualified Data.Map                   as M
import           Data.Text
import           Network.HTTP.Conduit
import           Proxmox.Models
import           Proxmox.Models.Network     (ProxmoxNetwork,
                                             ProxmoxNetworkFilter,
                                             ProxmoxNetworkType)
import           Proxmox.Models.Node
import           Proxmox.Models.SDNNetwork
import           Proxmox.Models.SDNZone
import           Proxmox.Models.Snapshot
import           Proxmox.Models.Storage
import           Proxmox.Models.Version
import           Proxmox.Models.VM          (ProxmoxVM, ProxmoxVMDeleteRequest,
                                             ProxmoxVMStatus,
                                             ProxmoxVMStatusWrapper)
import           Proxmox.Models.VMClone
import           Proxmox.Models.VMConfig    (ProxmoxVMConfig)
import           Servant.API
import           Servant.Client

data ProxmoxState = ProxmoxState BaseUrl Manager

type ProxmoxM m = ReaderT ProxmoxState IO m
type NodeNameCapture = Capture "nodename" Text
type SnapshotNameCapture = Capture "snapname" Text
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
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "config" :> ReqBody '[JSON] (M.Map String Value) :> Put '[JSON] (ProxmoxResponse ())
  :<|> "nodes" :> NodeNameCapture :> "storage" :> QueryParam "enabled" NumericBoolWrapper :> QueryParam "target" Text :> Get '[JSON] (ProxmoxResponse [ProxmoxStorage])
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "snapshot" :> Get '[JSON] (ProxmoxResponse [ProxmoxSnapshot])
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "snapshot" :> SnapshotNameCapture :> Delete '[JSON] ()
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "snapshot" :> SnapshotNameCapture :> "rollback" :> ReqBody '[JSON] ProxmoxRollbackParams :> Post '[JSON] ()
  :<|> "nodes" :> NodeNameCapture :> "qemu" :> VMIDCapture :> "snapshot" :> ReqBody '[JSON] ProxmoxSnapshotCreate :> Post '[JSON] (ProxmoxResponse String)

runProxmoxState :: ProxmoxState -> ProxmoxM a -> IO a
runProxmoxState = flip runReaderT

runProxmoxClient :: ClientM a -> ProxmoxM (Either ClientError a)
runProxmoxClient m = do
  ProxmoxState url manager' <- ask
  liftIO $ runClientM m (mkClientEnv manager' url)

runProxmoxClient' :: ProxmoxState -> ClientM a -> IO (Either ClientError a)
runProxmoxClient' state = runProxmoxState state . runProxmoxClient
