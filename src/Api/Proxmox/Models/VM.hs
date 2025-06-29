{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
module Api.Proxmox.Models.VM 
  ( ProxmoxVM(..)
  , ProxmoxVMStatus(..)
  , ProxmoxVMStatusWrapper(..)
  ) where

import Data.Aeson
import Data.Text
import qualified Data.Aeson.KeyMap as KM

newtype ProxmoxVMStatusWrapper = ProxmoxVMStatusWrapper ProxmoxVMStatus deriving Show

instance FromJSON ProxmoxVMStatusWrapper where
  parseJSON = withObject "ProxmoxVMStatusWrapper" $ \v -> ProxmoxVMStatusWrapper
    <$> v .: "status"

data ProxmoxVMStatus = VMRunning | VMStopped | VMUnknown Text deriving (Show, Eq)

instance FromJSON ProxmoxVMStatus where
  parseJSON = withText "ProxmoxVMStatus" $ \case
    "stopped" -> pure VMStopped
    "running" -> pure VMRunning
    otherValue -> pure (VMUnknown otherValue)

-- common vm details, represented in /nodes/{node}/qemu requets
data ProxmoxVM = ProxmoxVM
  { vmID :: !Int
  , vmName :: !(Maybe String)
  , vmTemplate :: !Bool
  , vmLock :: !(Maybe String)
  , vmStatus :: !ProxmoxVMStatus
  } deriving Show

instance FromJSON ProxmoxVM where
  parseJSON = withObject "ProxmoxVM" $ \v -> ProxmoxVM
    <$> v .: "vmid"
    <*> v .:? "name"
    <*> templateParser (KM.lookup "template" v)
    <*> v .:? "lock"
    <*> v .: "status" where
      templateParser Nothing = pure False
      templateParser (Just (Number 1)) = pure True
      templateParser (Just (String "1")) = pure True
      templateParser _ = pure False
