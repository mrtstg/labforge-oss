{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.SDNNetwork
  ( ProxmoxSDNNetwork(..)
  , ProxmoxSDNNetworkCreate(..)
  , defaultSDNNetworkCreate
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KV
import qualified Data.Text         as T

type Zone = String
type Name = String

data ProxmoxSDNNetwork = ProxmoxSDNNetwork
  { sdnNetworkZone   :: !String
  , sdnNetworkTag    :: !(Maybe Int)
  , sdnNetworkName   :: !String
  , sdnNetworkDigest :: !(Maybe String)
  , sdnNetworkState  :: !(Maybe String)
  } deriving (Show, Eq, Ord)

instance FromJSON ProxmoxSDNNetwork where
  parseJSON = withObject "ProxmoxSDNNetwork" $ \v -> ProxmoxSDNNetwork
    <$> fmap T.unpack (zoneParser v)
    <*> v .:? "tag"
    <*> v .: "vnet"
    <*> v .:? "digest"
    <*> v .:? "state" where
      zoneParser v = case KV.lookup "zone" v of
        (Just (String zone)) -> pure zone
        _anyOther -> case KV.lookup "pending" v of
          (Just (Object obj)) -> case KV.lookup "zone" obj of
            (Just (String zone')) -> pure zone'
            _anyOther             -> fail "Invalid pending zone type"
          _anyOther -> fail "Invalid pending object type"

instance ToJSON ProxmoxSDNNetwork where
  toJSON (ProxmoxSDNNetwork { .. }) = object
    [ "zone" .= sdnNetworkZone
    , "tag" .= sdnNetworkTag -- TODO: PARSER ON CONVERTING TO STRING
    , "vnet" .= sdnNetworkName
    , "digest" .= sdnNetworkDigest
    ]

data ProxmoxSDNNetworkCreate = ProxmoxSDNNetworkCreate
  { sdnNetworkCreateName      :: !String
  , sdnNetworkCreateZone      :: !String
  , sdnNetworkCreateTag       :: !(Maybe Int)
  , sdnNetworkCreateAlias     :: !(Maybe String)
  , sdnNetworkCreateVlanaware :: !(Maybe Bool)
  } deriving (Show, Eq, Ord)

instance ToJSON ProxmoxSDNNetworkCreate where
  toJSON (ProxmoxSDNNetworkCreate { .. }) = object $ baseFields ++ tagField ++ aliasField ++ vlanField where
    baseFields =
      [ "vnet" .= sdnNetworkCreateName
      , "zone" .= sdnNetworkCreateZone
      , "type" .= String "vnet"
      ]
    vlanField = case sdnNetworkCreateVlanaware of
      Nothing  -> []
      (Just v) -> ["vlanaware" .= v]
    tagField = case sdnNetworkCreateTag of
      Nothing  -> []
      (Just v) -> ["tag" .= v]
    aliasField = case sdnNetworkCreateAlias of
      Nothing  -> []
      (Just v) -> ["alias" .= v]

defaultSDNNetworkCreate :: Zone -> Name -> ProxmoxSDNNetworkCreate
defaultSDNNetworkCreate zone name = ProxmoxSDNNetworkCreate
  { sdnNetworkCreateZone = zone
  , sdnNetworkCreateName = name
  , sdnNetworkCreateAlias = Nothing
  , sdnNetworkCreateTag = Nothing
  , sdnNetworkCreateVlanaware = Nothing
  }
