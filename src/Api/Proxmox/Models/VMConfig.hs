{-# LANGUAGE OverloadedStrings #-}
module Api.Proxmox.Models.VMConfig 
  ( ProxmoxVMConfig(..)
  , vmConfigNetworkNumbers
  ) where

import qualified Data.Aeson.KeyMap as KM
import Data.Aeson
import Data.Aeson.Key (toString)
import qualified Data.Map as M
import Data.Text (Text, isPrefixOf, pack, replace, unpack)
import Text.Read (readMaybe)
import Data.Function ((&))
import Data.Maybe

-- detailed configuration, like in /nodes/{node}/qemu/{vmid}/config
data ProxmoxVMConfig = ProxmoxVMConfig
  { vmDigest :: !String
  , vmName :: !(Maybe String)
  , vmTemplate :: !Bool
  , vmLock :: !(Maybe String)
  , vmConfigMap :: !(M.Map String Value)
  }

instance FromJSON ProxmoxVMConfig where
  parseJSON = withObject "ProxmoxVMConfig" $ \v -> ProxmoxVMConfig
    <$> v .: "digest"
    <*> v .:? "name"
    <*> templateParser (KM.lookup "template" v)
    <*> v .:? "lock"
    <*> (pure . M.mapKeys toString . KM.toMap) v where
      templateParser Nothing = pure False
      templateParser (Just (Number 1)) = pure True
      templateParser (Just (String "1")) = pure True
      templateParser _ = pure False

vmConfigNetworkNumbers :: ProxmoxVMConfig -> [Int]
vmConfigNetworkNumbers (ProxmoxVMConfig { vmConfigMap = cfgMap }) = 
  M.keys cfgMap & map pack & filter ("net" `isPrefixOf`) & map (replace "net" "") & mapMaybe (readMaybe . unpack)
