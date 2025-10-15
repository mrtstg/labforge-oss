{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.Storage
  ( ProxmoxStorage(..)
  , ProxmoxStorageFilter(..)
  , defaultProxmoxStorageFilter
  , ProxmoxAllocateRequest(..)
  , ProxmoxAllocateFormat(..)
  , ProxmoxStorageContent(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap     as KM
import           Data.Text
import           Proxmox.Utils.Parsers

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

data ProxmoxStorageContent = ProxmoxStorageContent
  { proxmoxContentFormat :: !String
  , proxmoxContentSize   :: !Int
  , proxmoxContentCTime  :: !(Maybe Int)
  , proxmoxContentVMID   :: !(Maybe Int)
  , proxmoxContentVolID  :: !String
  } deriving (Show, Eq)

instance FromJSON ProxmoxStorageContent where
  parseJSON = withObject "ProxmoxStorageContent" $ \v -> ProxmoxStorageContent
    <$> v .: "format"
    <*> v .:? "size" .!= 0
    <*> v .: "ctime"
    <*> v .:? "vmid"
    <*> v .:? "volid" .!= ""

instance ToJSON ProxmoxStorageContent where
  toJSON (ProxmoxStorageContent { .. }) = object
    [ "format" .= proxmoxContentFormat
    , "size" .= proxmoxContentSize
    , "ctime" .= proxmoxContentCTime
    , "vmid" .= proxmoxContentVMID
    , "volid" .= proxmoxContentVolID
    ]

data ProxmoxAllocateFormat = Raw | Qcow2 | SubVol | VMDK deriving (Show, Eq, Enum, Ord)

instance ToJSON ProxmoxAllocateFormat where
  toJSON Raw    = String "raw"
  toJSON Qcow2  = String "qcow2"
  toJSON SubVol = String "subvol"
  toJSON VMDK   = String "vmdk"

instance FromJSON ProxmoxAllocateFormat where
  parseJSON = withText "ProxmoxAllocateFormat" $ \case
    "raw" -> pure Raw
    "qcow2" -> pure Qcow2
    "subvol" -> pure SubVol
    "vmdk" -> pure VMDK
    _anyOther -> fail "Invalid allocate format"

data ProxmoxAllocateRequest = ProxmoxAllocateRequest
  { allocFilename :: !String
  , allocSize     :: !String
  , allocVMID     :: !Int
  , allocFormat   :: !(Maybe ProxmoxAllocateFormat)
  } deriving (Show, Eq, Ord)

instance ToJSON ProxmoxAllocateRequest where
  toJSON (ProxmoxAllocateRequest { .. }) = object
    [ "filename" .= allocFilename
    , "size" .= allocSize
    , "vmid" .= allocVMID
    , "format" .= allocFormat
    ]

instance FromJSON ProxmoxAllocateRequest where
  parseJSON = withObject "ProxmoxAllocateRequest" $ \v -> ProxmoxAllocateRequest
    <$> v .: "filename"
    <*> v .: "size"
    <*> v .: "vmid"
    <*> v .: "format"
