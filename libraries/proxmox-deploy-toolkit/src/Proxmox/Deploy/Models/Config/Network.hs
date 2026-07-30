{- Copyright (C) 2025 Ilya Zamaratskikh

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, see <http://www.gnu.org/licenses>. -}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Deploy.Models.Config.Network
  ( ConfigNetwork(..)
  , isSDNNetwork
  , isExistingNetwork
  , isBridgeNetwork
  ) where

import           Control.Applicative
import           Data.Aeson
import qualified Data.Aeson.KeyMap   as KV
import qualified Data.Text           as T

data ConfigSubnetRange = ConfigSubnetRange
  { configSubnetRangeStart :: !String
  , configSubnetRangeEnd   :: !String
  } deriving (Show, Eq, Ord)

instance FromJSON ConfigSubnetRange where
  parseJSON = withObject "ConfigSubnetRange" $ \v -> ConfigSubnetRange
    <$> (v .: "start" <|> v .: "begin")
    <*> v .: "end"

instance ToJSON ConfigSubnetRange where
  toJSON (ConfigSubnetRange { .. }) = object
    [ "start" .= configSubnetRangeStart
    , "end" .= configSubnetRangeEnd
    ]

data ConfigSubnet = ConfigSubnet
  { configSubnetCIDR      :: !String
  , configSubnetDNS       :: !(Maybe String)
  , configSubnetDNSPrefix :: !(Maybe String)
  , configSubnetGateway   :: !(Maybe String)
  , configSubnetSNAT      :: !Bool
  , configSubnetRanges    :: ![ConfigSubnetRange]
  } deriving (Show, Eq, Ord)

instance ToJSON ConfigSubnet where
  toJSON (ConfigSubnet { .. }) = object
    [ "cidr" .= configSubnetCIDR
    , "dns" .= configSubnetDNS
    , "dns_prefix" .= configSubnetDNSPrefix
    , "gateway" .= configSubnetGateway
    , "snat" .= configSubnetSNAT
    , "dhcp_ranges" .= configSubnetRanges
    ]

instance FromJSON ConfigSubnet where
  parseJSON = withObject "ConfigSubnet" $ \v -> ConfigSubnet
    <$> v .: "cidr"
    <*> v .:? "dns"
    <*> v .:? "dns_prefix"
    <*> v .:? "gateway"
    <*> v .:? "snat" .!= False
    <*> v .:? "dhcp_ranges" .!= []

data ConfigNetwork = ExistingNetwork
  { configNetworkName :: !String
  } |
  SDNNetwork
  { configNetworkSubnets   :: ![ConfigSubnet]
  , configNetworkZone      :: !String
  , configNetworkName      :: !String
  , configNetworkVLANAware :: !(Maybe Bool)
  } |
  BridgeNetwork
  { configNetworkName      :: !String
  , configNetworkAutostart :: !Bool
  } deriving (Show, Eq, Ord)

isSDNNetwork :: ConfigNetwork -> Bool
isSDNNetwork (SDNNetwork {}) = True
isSDNNetwork _               = False

isExistingNetwork :: ConfigNetwork -> Bool
isExistingNetwork (ExistingNetwork {}) = True
isExistingNetwork _                    = False

isBridgeNetwork :: ConfigNetwork -> Bool
isBridgeNetwork (BridgeNetwork {}) = True
isBridgeNetwork _                  = False

instance ToJSON ConfigNetwork where
  toJSON (ExistingNetwork { .. }) = object [ "type" .= String "existing", "name" .= configNetworkName ]
  toJSON (SDNNetwork { .. }) = object
    [ "type" .= String "sdn"
    , "name" .= configNetworkName
    , "subnets" .= configNetworkSubnets
    , "zone" .= configNetworkZone
    , "vlanaware" .= configNetworkVLANAware
    ]
  toJSON (BridgeNetwork { .. }) = object
    [ "type" .= String "bridge"
    , "name" .= configNetworkName
    , "autostart" .= configNetworkAutostart
    ]

instance FromJSON ConfigNetwork where
  parseJSON (String network) = pure $ ExistingNetwork (T.unpack network)
  parseJSON otherValue = let
    existingNetworkParser v = ExistingNetwork
      <$> v .: "name"
    sdnNetworkParser v = SDNNetwork
      <$> v .:? "subnets" .!= []
      <*> v .: "zone"
      <*> v .: "name"
      <*> v .:? "vlanaware"
    bridgeNetworkParser v = BridgeNetwork
      <$> v .: "name"
      <*> v .:? "autostart" .!= True
    in flip (withObject "ConfigNetwork") otherValue $ \v -> case KV.lookup "type" v of
    Nothing           -> existingNetworkParser v
    (Just "existing") -> existingNetworkParser v
    (Just "sdn")      -> sdnNetworkParser v
    (Just "bridge")   -> bridgeNetworkParser v
    _anyOther         -> fail $ "Invalid network type value: " <> show _anyOther
