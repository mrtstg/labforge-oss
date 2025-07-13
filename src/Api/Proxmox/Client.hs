{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeOperators     #-}
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
  , deleteVM
  , deleteVM'
  , cloneVM
  , getActiveNodeVMNodeMap
  , createSDNNetwork
  , applySDNSettings
  , deleteSDNNetwork
  , putVMConfig
  , deleteVMConfig
  ) where

import           Api.Proxmox
import           Api.Proxmox.Models
import           Api.Proxmox.Models.Network
import           Api.Proxmox.Models.Node
import           Api.Proxmox.Models.SDNNetwork
import           Api.Proxmox.Models.VM
import           Api.Proxmox.Models.VMClone
import           Api.Proxmox.Models.VMConfig
import           Control.Monad.Except          (throwError)
import           Control.Monad.IO.Class        (liftIO)
import           Control.Monad.Reader          (ask)
import           Data.Aeson
import           Data.List                     (intercalate)
import qualified Data.Map                      as M
import           Data.Proxy
import           Data.Text                     (Text, pack)
import           GHC.Generics
import           Network.HTTP.Client           (defaultManagerSettings,
                                                newManager, responseStatus)
import           Network.HTTP.Types            (Status (..))
import           Servant.API
import           Servant.Client
import qualified Servant.Client.Streaming      as S

api :: Proxy ProxmoxAPI
api = Proxy

getVersion
  :<|> getSDNZones
  :<|> getSDNNetworks
  :<|> createSDNNetwork
  :<|> applySDNSettings
  :<|> getVMConfig'
  :<|> getNodeVMs
  :<|> getNodeNetworks
  :<|> getNodes
  :<|> startVM
  :<|> stopVM
  :<|> getVMPower
  :<|> deleteVM
  :<|> cloneVM
  :<|> deleteSDNNetwork
  :<|> putVMConfig = client api

getVMConfig :: Text -> Int -> ClientM (ProxmoxResponse (Maybe ProxmoxVMConfig))
getVMConfig nodeName vmid = do
  state <- ask
  res <- (liftIO . flip runClientM state) $ getVMConfig' nodeName vmid
  case res of
    (Right resp)                    -> pure resp
    (Left exception@(FailureResponse _ (Response { responseStatusCode = status }))) -> do
      case statusCode status of
        404          -> pure (ProxmoxResponse Nothing Nothing)
        _otherStatus -> throwError exception
    (Left otherError)               -> throwError otherError

deleteVMConfig :: Text -> Int -> [String] -> ClientM (ProxmoxResponse ())
deleteVMConfig _ _ [] = pure (ProxmoxResponse () Nothing)
deleteVMConfig node vmid deleteList = putVMConfig node vmid (M.fromList [("delete", (String . pack . intercalate ",") deleteList)])

deleteVM' :: Text -> Int -> ProxmoxVMDeleteRequest -> ClientM (ProxmoxResponse String)
deleteVM' node vmid (ProxmoxVMDeleteRequest { .. }) = deleteVM
  node
  vmid
  (Just . NumericBoolWrapper $ proxmoxDestroyUnrefferenced)
  (Just . NumericBoolWrapper $ proxmoxPurgeVM)
  (Just . NumericBoolWrapper $ proxmoxSkipLock)

getActiveNodesVMMap :: ClientM (M.Map Int ProxmoxVM)
getActiveNodesVMMap = do
  nodes <- getActiveNodes
  nodeMaps <- traverse (getNodeVMsMap . pack . nodeName) nodes
  return $ foldr (M.unionWith const) M.empty nodeMaps

getActiveNodeVMNodeMap :: ClientM (M.Map Int String)
getActiveNodeVMNodeMap = let
  f :: M.Map Int String -> [ProxmoxNode] -> ClientM (M.Map Int String)
  f acc [] = pure acc
  f acc (ProxmoxNode { nodeName = nodeName }:nodes) = do
    nodeMap <- getNodeVMsMap (pack nodeName)
    let newAcc = foldr (\(vmid, _) acc' -> M.insert vmid nodeName acc') acc (M.toList nodeMap)
    f newAcc nodes
  in do
    nodes <- getActiveNodes
    f M.empty nodes

getNodeVMsMap :: Text -> ClientM (M.Map Int ProxmoxVM)
getNodeVMsMap node = getNodeVMs node >>= f where
  f :: ProxmoxResponse [ProxmoxVM] -> ClientM (M.Map Int ProxmoxVM)
  f (ProxmoxResponse { proxmoxData = vms }) = (pure . M.fromList) $ map (\x -> (vmID x, x)) vms

-- shortcut for getting networks for plugging vms into
getBridgeNodeNetworks :: Text -> ClientM [ProxmoxNetwork]
getBridgeNodeNetworks node = do
  (ProxmoxResponse { proxmoxData = nets }) <- getNodeNetworks node (Just AnyBridge)
  return nets

getActiveNodes :: ClientM [ProxmoxNode]
getActiveNodes = do
  (ProxmoxResponse { proxmoxData = nodes }) <- getNodes
  return $ filter ((== NodeOnline) . nodeStatus) nodes
