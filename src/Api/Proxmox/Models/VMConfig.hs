{-# LANGUAGE OverloadedStrings #-}
module Api.Proxmox.Models.VMConfig 
  ( ProxmoxVMConfig(..)
  ) where

import Data.Aeson

-- detailed configuration, like in /nodes/{node}/qemu/{vmid}/config
data ProxmoxVMConfig = ProxmoxVMConfig
  { vmDigest :: !String
  , vmName :: !(Maybe String)
  , vmTemplate :: !Bool
  , vmLock :: !(Maybe String)
  }

instance FromJSON ProxmoxVMConfig where
  parseJSON = withObject "ProxmoxVMConfig" $ \v -> ProxmoxVMConfig
    <$> v .: "digest"
    <*> v .:? "name"
    <*> v .:? "template" .!= False
    <*> v .:? "lock"
