{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Config.Network 
  ( ConfigNetwork(..)
  ) where

import Data.Aeson
import qualified Data.Aeson.KeyMap as KV
import Control.Applicative

data ConfigSubnetRange = ConfigSubnetRange
  { configSubnetRangeStart :: !String
  , configSubnetRangeEnd :: !String
  } deriving (Show, Eq)

instance FromJSON ConfigSubnetRange where
  parseJSON = withObject "ConfigSubnetRange" $ \v -> ConfigSubnetRange
    <$> (v .: "start" <|> v .: "begin")
    <*> v .: "end"

data ConfigSubnet = ConfigSubnet 
  { configSubnetCIDR :: !String
  , configSubnetDNS :: !(Maybe String)
  , configSubnetDNSPrefix :: !(Maybe String)
  , configSubnetGateway :: !(Maybe String)
  , configSubnetSNAT :: !Bool
  , configSubnetRanges :: ![ConfigSubnetRange]
  } deriving (Show, Eq)

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
  { configNetworkSubnets :: ![ConfigSubnet]
  , configNetworkZone :: !String
  , configNetworkName :: !String
  , configNetworkVLANAware :: !(Maybe Bool)
  } deriving (Show, Eq)

instance FromJSON ConfigNetwork where
  parseJSON = let
    existingNetworkParser v = ExistingNetwork
      <$> v .: "name"
    sdnNetworkParser v = SDNNetwork
      <$> v .:? "subnets" .!= []
      <*> v .: "zone"
      <*> v .: "name"
      <*> v .:? "vlanaware"
    in withObject "ConfigNetwork" $ \v -> case KV.lookup "type" v of
    Nothing -> existingNetworkParser v
    (Just "existing") -> existingNetworkParser v
    (Just "sdn") -> sdnNetworkParser v
    _anyOther -> fail $ "Invalid network type value: " <> show _anyOther
