{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.VM
  ( ProxmoxVM(..)
  , ProxmoxVMStatus(..)
  , ProxmoxVMStatusWrapper(..)
  , ProxmoxVMDeleteRequest(..)
  , defaultProxmoxVMDeleteRequest
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import           Data.Text

data ProxmoxVMDeleteRequest = ProxmoxVMDeleteRequest
  { proxmoxPurgeVM              :: !Bool
  , proxmoxSkipLock             :: !Bool
  , proxmoxDestroyUnrefferenced :: !Bool
  } deriving (Show, Eq, Ord)

instance ToJSON ProxmoxVMDeleteRequest where
  toJSON (ProxmoxVMDeleteRequest { .. }) = object
    [ "purge" .= if proxmoxPurgeVM then String "1" else "0"
    , "destroy-unreferenced-disks" .= if proxmoxPurgeVM then String "1" else "0"
    , "skiplock" .= if proxmoxSkipLock then String "1" else "0"
    ]

defaultProxmoxVMDeleteRequest :: ProxmoxVMDeleteRequest
defaultProxmoxVMDeleteRequest = ProxmoxVMDeleteRequest True False False

newtype ProxmoxVMStatusWrapper = ProxmoxVMStatusWrapper ProxmoxVMStatus deriving Show

instance FromJSON ProxmoxVMStatusWrapper where
  parseJSON = withObject "ProxmoxVMStatusWrapper" $ \v -> ProxmoxVMStatusWrapper
    <$> v .: "status"

data ProxmoxVMStatus = VMRunning | VMStopped | VMUnknown Text deriving (Show, Eq, Ord)

instance FromJSON ProxmoxVMStatus where
  parseJSON = withText "ProxmoxVMStatus" $ \case
    "stopped" -> pure VMStopped
    "running" -> pure VMRunning
    otherValue -> pure (VMUnknown otherValue)

-- common vm details, represented in /nodes/{node}/qemu requets
-- TODO: add proxmox prefix
data ProxmoxVM = ProxmoxVM
  { vmID       :: !Int
  , vmName     :: !(Maybe String)
  , vmTemplate :: !Bool
  , vmLock     :: !(Maybe String)
  , vmStatus   :: !ProxmoxVMStatus
  } deriving (Show, Eq, Ord)

instance FromJSON ProxmoxVM where
  parseJSON = withObject "ProxmoxVM" $ \v -> ProxmoxVM
    <$> v .: "vmid"
    <*> v .:? "name"
    <*> templateParser (KM.lookup "template" v)
    <*> v .:? "lock"
    <*> v .: "status" where
      templateParser Nothing             = pure False
      templateParser (Just (Number 1))   = pure True
      templateParser (Just (String "1")) = pure True
      templateParser _                   = pure False
