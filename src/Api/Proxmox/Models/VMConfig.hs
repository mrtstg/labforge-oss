{-# LANGUAGE OverloadedStrings #-}
module Api.Proxmox.Models.VMConfig 
  ( ProxmoxVMConfig(..)
  ) where

import qualified Data.Aeson.KeyMap as KM
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
    <*> templateParser (KM.lookup "template" v)
    <*> v .:? "lock" where
      templateParser Nothing = pure False
      templateParser (Just (Number 1)) = pure True
      templateParser (Just (String "1")) = pure True
      templateParser _ = pure False
