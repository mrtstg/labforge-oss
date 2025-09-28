{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.Snapshot
  ( ProxmoxSnapshot(..)
  , ProxmoxSnapshotCreate(..)
  , ProxmoxRollbackParams(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import           Data.Maybe
import           Data.Text         (Text, pack)
import           Parsers

data ProxmoxSnapshot = ProxmoxSnapshot
  { snapshotDescription :: !Text
  , snapshotName        :: !Text
  , snapshotParent      :: !(Maybe Text)
  , snapshotTime        :: !(Maybe Int)
  , snapshotStateful    :: !(Maybe Bool)
  } deriving (Show, Eq, Ord)

instance FromJSON ProxmoxSnapshot where
  parseJSON = withObject "ProxmoxSnapshot" $ \v -> ProxmoxSnapshot
    <$> v .:? "description" .!= ""
    <*> v .: "name"
    <*> v .:? "parent"
    <*> nullMaybeWrapper (KM.lookup "snaptime" v) intStringParser
    <*> nullMaybeWrapper (KM.lookup "vmstate" v) variableBooleanParser

instance ToJSON ProxmoxSnapshot where
  toJSON (ProxmoxSnapshot { .. }) = object
    [ "description" .= snapshotDescription
    , "name" .= snapshotName
    , "parent" .= snapshotParent
    , "snaptime" .= snapshotTime
    , "vmstate" .= snapshotStateful
    ]

data ProxmoxSnapshotCreate = ProxmoxSnapshotCreate
  { snapshotCreateDesc     :: !(Maybe Text)
  , snapshotCreateName     :: !Text
  , snapshotCreateStateful :: !(Maybe Bool)
  } deriving (Show, Eq, Ord)

instance FromJSON ProxmoxSnapshotCreate where
  parseJSON = withObject "ProxmoxSnapshotCreate" $ \v -> ProxmoxSnapshotCreate
    <$> v .:? "description"
    <*> v .: "snapname"
    <*> nullMaybeWrapper (KM.lookup "vmstate" v) variableBooleanParser

instance ToJSON ProxmoxSnapshotCreate where
  toJSON (ProxmoxSnapshotCreate { .. }) = object
    [ "description" .= snapshotCreateDesc
    , "snapname" .= snapshotCreateName
    , "vmstate" .= snapshotCreateStateful
    ]

data ProxmoxRollbackParams = ProxmoxRollbackParams
  { rollbackStart :: !Bool
  } deriving (Show, Eq, Ord)

instance ToJSON ProxmoxRollbackParams where
  toJSON (ProxmoxRollbackParams start) = object ["start" .= start]
