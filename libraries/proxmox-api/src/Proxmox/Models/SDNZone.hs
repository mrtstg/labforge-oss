{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.SDNZone
  ( ProxmoxSDNZone(..)
  ) where

import           Data.Aeson

data ProxmoxSDNZone = ProxmoxSDNZone
  { proxmoxSDNZoneType       :: !String
  , proxmoxSDNZoneName       :: !String
  , proxmoxSDNZoneDhcp       :: !(Maybe String)
  , proxmoxSDNZoneDns        :: !(Maybe String)
  , proxmoxSDNZoneDnszone    :: !(Maybe String)
  , proxmoxSDNZoneIpam       :: !(Maybe String)
  , proxmoxSDNZoneMtu        :: !(Maybe Int)
  , proxmoxSDNZoneNodes      :: !(Maybe String)
  , proxmoxSDNZonePending    :: !(Maybe Bool)
  , proxmoxSDNZoneReverseDns :: !(Maybe String)
  , proxmoxSDNZoneState      :: !(Maybe String)
  } deriving (Show, Eq, Ord)

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
