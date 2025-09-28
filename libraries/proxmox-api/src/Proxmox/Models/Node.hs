{-# LANGUAGE OverloadedStrings #-}
module Proxmox.Models.Node
  ( ProxmoxNode(..)
  , ProxmoxNodeStatus(..)
  ) where

import           Data.Aeson
import           Data.Text  (toLower)

data ProxmoxNodeStatus = NodeUnknown | NodeOnline | NodeOffline deriving (Show, Eq, Enum, Ord)

instance FromJSON ProxmoxNodeStatus where
  parseJSON = withText "ProxmoxNodeStatus" $ \v -> case toLower v of
    "online"  -> pure NodeOnline
    "offline" -> pure NodeOffline
    _anyOther -> pure NodeUnknown

data ProxmoxNode = ProxmoxNode
  { nodeId        :: !String
  , nodeName      :: !String
  , nodeStatus    :: !ProxmoxNodeStatus
  -- from 0 to 1
  , nodeCPU       :: !(Maybe Float)
  , nodeMaxCPU    :: !(Maybe Int)
  , nodeMaxMemory :: !(Maybe Int)
  -- in bytes
  , nodeMemory    :: !(Maybe Int)
  , nodeUptime    :: !(Maybe Int)
  } deriving (Show, Eq, Ord)

instance FromJSON ProxmoxNode where
  parseJSON = withObject "ProxmoxNode" $ \v -> ProxmoxNode
    <$> v .: "id"
    <*> v .: "node"
    <*> v .:? "status" .!= NodeUnknown
    <*> v .:? "cpu"
    <*> v .:? "maxcpu"
    <*> v .:? "maxmem"
    <*> v .:? "mem"
    <*> v .:? "uptime"
