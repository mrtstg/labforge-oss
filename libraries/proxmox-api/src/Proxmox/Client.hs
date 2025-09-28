{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeOperators     #-}
module Proxmox.Client
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
  , getNodeStorage
  , getVMSnapshots
  , deleteVMSnapshot
  , rollbackVM
  , createSnapshot
  ) where


import           Control.Monad.Except      (throwError)
import           Control.Monad.IO.Class    (liftIO)
import           Control.Monad.Reader      (ask)
import           Data.Aeson
import           Data.List                 (intercalate)
import qualified Data.Map                  as M
import           Data.Proxy
import           Data.Text                 (Text, isInfixOf, pack)
import           GHC.Generics
import           Network.HTTP.Client       (defaultManagerSettings, newManager,
                                            responseStatus)
import           Network.HTTP.Types        (Status (..))
import           Proxmox.Models
import           Proxmox.Models.Network
import           Proxmox.Models.Node
import           Proxmox.Models.SDNNetwork
import           Proxmox.Models.Storage
import           Proxmox.Models.VM
import           Proxmox.Models.VMClone
import           Proxmox.Models.VMConfig
import           Proxmox.Schema
import           Servant.API
import           Servant.Client
import qualified Servant.Client.Streaming  as S

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
  :<|> getVMPower'
  :<|> deleteVM
  :<|> cloneVM
  :<|> deleteSDNNetwork
  :<|> putVMConfig
  :<|> getNodeStorage'
  :<|> getVMSnapshots
  :<|> deleteVMSnapshot
  :<|> rollbackVM
  :<|> createSnapshot = client api

getNodeStorage :: Text -> ProxmoxStorageFilter -> ClientM [ProxmoxStorage]
getNodeStorage nodeName (ProxmoxStorageFilter { .. }) = do
  (ProxmoxResponse { proxmoxData = storages }) <- getNodeStorage' nodeName enabled storageTarget
  pure storages where
    enabled = case storageEnabled of
      (Just v) -> Just (NumericBoolWrapper v)
      Nothing  -> Nothing

getVMPower :: Text -> Int -> ClientM (ProxmoxResponse (Maybe ProxmoxVMStatusWrapper))
getVMPower nodeName vmid = do
  state <- ask
  res <- (liftIO . flip runClientM state) $ getVMPower' nodeName vmid
  case res of
    (Right (ProxmoxResponse { proxmoxData = resp }))                    -> pure (ProxmoxResponse { proxmoxData = Just resp, proxmoxMessage = Nothing })
    (Left exception@(FailureResponse _ (Response { responseStatusCode = status, responseBody = body }))) -> do
      case statusCode status of
        500          -> do
          case decode body of
            (Just (ProxmoxResponse { proxmoxData = (), proxmoxMessage = (Just (String msg)) })) ->
              if "Configuration file" `isInfixOf` msg && "does not exist" `isInfixOf` msg then
                pure (ProxmoxResponse { proxmoxData = Nothing, proxmoxMessage = Nothing }) else throwError exception
            _anyOther -> throwError exception
        _otherStatus -> throwError exception
    (Left otherError)               -> throwError otherError

getVMConfig :: Text -> Int -> ClientM (ProxmoxResponse (Maybe ProxmoxVMConfig))
getVMConfig nodeName vmid = do
  state <- ask
  res <- (liftIO . flip runClientM state) $ getVMConfig' nodeName vmid
  case res of
    (Right resp)                    -> pure resp
    (Left exception@(FailureResponse _ (Response { responseStatusCode = status, responseBody = body }))) -> do
      case statusCode status of
        500          -> do
          case decode body of
            (Just (ProxmoxResponse { proxmoxData = (), proxmoxMessage = (Just (String msg)) })) ->
              if "Configuration file" `isInfixOf` msg && "does not exist" `isInfixOf` msg then
                pure (ProxmoxResponse { proxmoxData = Nothing, proxmoxMessage = Nothing }) else throwError exception
            _anyOther -> throwError exception
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
