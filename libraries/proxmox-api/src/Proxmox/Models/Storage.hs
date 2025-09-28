{-# LANGUAGE OverloadedStrings #-}
module Proxmox.Models.Storage
  ( ProxmoxStorage(..)
  , ProxmoxStorageFilter(..)
  , defaultProxmoxStorageFilter
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import           Data.Text
import           Parsers

data ProxmoxStorageFilter = ProxmoxStorageFilter
  { storageEnabled :: !(Maybe Bool)
  , storageTarget  :: !(Maybe Text)
  } deriving (Show, Eq, Ord)

defaultProxmoxStorageFilter = ProxmoxStorageFilter Nothing Nothing

data ProxmoxStorage = DirectoryStorage
  { proxmoxStorage        :: !String
  , proxmoxStorageActive  :: !Bool
  , proxmoxStorageEnabled :: !Bool
  , proxmoxStorageShared  :: !Bool
  } | GenericStorage
  { proxmoxStorage        :: !String
  , proxmoxStorageActive  :: !Bool
  , proxmoxStorageEnabled :: !Bool
  , proxmoxStorageShared  :: !Bool
  } deriving (Show, Eq, Ord)

genericStorageParser v c = c
  <$> v .: "storage"
  <*> nullDefaultWrapper (KM.lookup "active" v) False variableBooleanParser
  <*> nullDefaultWrapper (KM.lookup "enabled" v) False variableBooleanParser
  <*> nullDefaultWrapper (KM.lookup "shared" v) False variableBooleanParser

instance FromJSON ProxmoxStorage where
  parseJSON = withObject "ProxmoxStorage" $ \v -> case KM.lookup "type" v of
    (Just (String "dir")) -> genericStorageParser v DirectoryStorage
    _                     -> genericStorageParser v GenericStorage
