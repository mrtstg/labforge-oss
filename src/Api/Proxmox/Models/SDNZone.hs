{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api.Proxmox.Models.SDNZone 
  ( ProxmoxSDNZone(..)
  ) where

import           Data.Aeson

data ProxmoxSDNZone = ProxmoxSDNZone
  { sdnZoneType       :: !String
  , sdnZoneName       :: !String
  , sdnZoneDhcp       :: !(Maybe String)
  , sdnZoneDns        :: !(Maybe String)
  , sdnZoneDnszone    :: !(Maybe String)
  , sdnZoneIpam       :: !(Maybe String)
  , sdnZoneMtu        :: !(Maybe Int)
  , sdnZoneNodes      :: !(Maybe String)
  , sdnZonePending    :: !(Maybe Bool)
  , sdnZoneReverseDns :: !(Maybe String)
  , sdnZoneState      :: !(Maybe String)
  } deriving Show

instance FromJSON ProxmoxSDNZone where
  parseJSON = withObject "ProxmoxSDNZone" $ \v -> ProxmoxSDNZone
    <$> v .: "type"
    <*> v .: "zone"
    <*> v .:? "dhcp"
    <*> v .:? "dns"
    <*> v .:? "dnszone"
    <*> v .:? "ipam"
    <*> v .:? "mtu"
    <*> v .:? "nodes"
    <*> v .:? "pending"
    <*> v .:? "reversedns"
    <*> v .:? "state"
