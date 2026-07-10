{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.Network
  ( ProxmoxNetworkType(..)
  , ProxmoxNetwork(..)
  , ProxmoxNetworkFilter(..)
  , ProxmoxNetworkResponse(..)
  , ProxmoxNetworkCreate(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import           Data.Text         (Text, pack, unpack)
import           Servant.API       (ToHttpApiData (..))

data ProxmoxNetworkCreate = ProxmoxNetworkCreate
  { networkCreateInterface :: !String
  , networkCreateType      :: !ProxmoxNetworkType
  , networkCreateAutostart :: !Bool
  } deriving (Show, Eq)

instance ToJSON ProxmoxNetworkCreate where
  toJSON (ProxmoxNetworkCreate { .. }) = object
    [ "iface" .= networkCreateInterface
    , "type" .= networkCreateType
    , "autostart" .= networkCreateAutostart
    ]

instance FromJSON ProxmoxNetworkCreate where
  parseJSON = withObject "ProxmoxNetworkCreate" $ \v -> ProxmoxNetworkCreate
    <$> v .: "iface"
    <*> v .: "type"
    <*> v .: "autostart"

data ProxmoxNetworkResponse = ProxmoxNetworkResponse
  { proxmoxNetworks       :: ![ProxmoxNetwork]
  , proxmoxNetworkChanges :: !(Maybe String)
  } deriving (Show, Eq)

instance FromJSON ProxmoxNetworkResponse where
  parseJSON = withObject "ProxmoxNetworkResponse" $ \v -> ProxmoxNetworkResponse
    <$> v .: "data"
    <*> v .:? "changes"

data ProxmoxNetworkFilter = AnyBridge | AnyLocalBridge | TypedNetwork ProxmoxNetworkType deriving (Eq, Ord)

instance Show ProxmoxNetworkFilter where
  show AnyBridge        = "any_bridge"
  show AnyLocalBridge   = "any_local_bridge"
  show (TypedNetwork t) = show t

instance ToHttpApiData ProxmoxNetworkFilter where
  toQueryParam = pack . show

data ProxmoxNetworkType = Bridge | Bond | Eth | Alias | Vlan | OVSBridge | OVSBond | OVSPort | OVSIntPort | Vnet | Unknown Text deriving (Eq, Ord)

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

instance ToJSON ProxmoxNetworkType where
  toJSON = String . pack . show

instance Show ProxmoxNetworkType where
  show Bridge      = "bridge"
  show Bond        = "bond"
  show Eth         = "eth"
  show Alias       = "alias"
  show Vlan        = "vlan"
  show OVSBridge   = "OVSBridge"
  show OVSBond     = "OVSBond"
  show OVSPort     = "OVSPort"
  show OVSIntPort  = "OVSIntPort"
  show Vnet        = "vnet"
  show (Unknown v) = unpack v

data ProxmoxNetwork = ProxmoxNetwork
  { proxmoxNetworkInterface :: !String
  , proxmoxNetworkType      :: !ProxmoxNetworkType
  , proxmoxNetworkActive    :: !(Maybe Bool)
  } deriving (Show, Eq, Ord)

instance FromJSON ProxmoxNetwork where
  parseJSON = withObject "ProxmoxNetwork" $ \v -> ProxmoxNetwork
    <$> v .: "iface"
    <*> v .: "type"
    <*> activeFlagParser (KM.lookup "active" v) where
      activeFlagParser (Just (Number 1))   = (pure . Just) True
      activeFlagParser (Just (String "1")) = (pure . Just) True
      activeFlagParser (Just _)            = (pure . Just) False
      activeFlagParser Nothing             = pure Nothing
