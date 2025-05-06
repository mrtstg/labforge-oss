{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
module Api.Proxmox.Models.Network 
  ( ProxmoxNetworkType(..)
  , ProxmoxNetwork(..)
  , ProxmoxNetworkFilter(..)
  ) where

import Data.Text (Text, pack, unpack)
import Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import Servant.API (ToHttpApiData(..))

data ProxmoxNetworkFilter = AnyBridge | AnyLocalBridge | TypedNetwork ProxmoxNetworkType

instance Show ProxmoxNetworkFilter where
  show AnyBridge = "any_bridge"
  show AnyLocalBridge = "any_local_bridge"
  show (TypedNetwork t) = show t

instance ToHttpApiData ProxmoxNetworkFilter where
  toQueryParam = pack . show

data ProxmoxNetworkType = Bridge | Bond | Eth | Alias | Vlan | OVSBridge | OVSBond | OVSPort | OVSIntPort | Vnet | Unknown Text

instance FromJSON ProxmoxNetworkType where
  parseJSON = withText "ProxmoxNetworkType" $ \case
    "bridge" -> pure Bridge
    "bond" -> pure Bond
    "eth" -> pure Eth
    "alias" -> pure Alias
    "vlan" -> pure Vlan
    "OVSBridge" -> pure OVSBridge
    "OVSBond" -> pure OVSBond
    "OVSPort" -> pure OVSPort
    "OVSIntPort" -> pure OVSIntPort
    "vnet" -> pure Vnet
    anyOther -> pure $ Unknown anyOther

instance Show ProxmoxNetworkType where
  show Bridge = "bridge"
  show Bond = "bond"
  show Eth = "eth"
  show Alias = "alias"
  show Vlan = "vlan"
  show OVSBridge = "OVSBridge"
  show OVSBond = "OVSBond"
  show OVSPort = "OVSPort"
  show OVSIntPort = "OVSIntPort"
  show Vnet = "vnet"
  show (Unknown v) = unpack v

data ProxmoxNetwork = ProxmoxNetwork 
  { proxmoxNetworkInterface :: !String
  , proxmoxNetworkType :: !ProxmoxNetworkType
  , proxmoxNetworkActive :: !(Maybe Bool)
  } deriving Show

instance FromJSON ProxmoxNetwork where
  parseJSON = withObject "ProxmoxNetwork" $ \v -> ProxmoxNetwork
    <$> v .: "iface"
    <*> v .: "type"
    <*> activeFlagParser (KM.lookup "active" v) where
      activeFlagParser (Just (Number 1)) = (pure . Just) True
      activeFlagParser (Just (String "1")) = (pure . Just) True
      activeFlagParser (Just _) = (pure . Just) False
      activeFlagParser Nothing = pure Nothing
