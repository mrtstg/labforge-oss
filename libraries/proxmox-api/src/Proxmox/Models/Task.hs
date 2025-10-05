{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.Task
  ( ProxmoxTask(..)
  , ProxmoxTaskSource(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KV
import           Data.Text
import           Parsers
import           Servant.API

data ProxmoxTaskSource = ArchiveTasks | ActiveTasks | AllTasks deriving (Show, Eq, Enum, Ord)

instance ToHttpApiData ProxmoxTaskSource where
  toQueryParam ArchiveTasks = "archive"
  toQueryParam ActiveTasks  = "active"
  toQueryParam AllTasks     = "all"

instance ToJSON ProxmoxTaskSource where
  toJSON ArchiveTasks = String "archive"
  toJSON ActiveTasks  = String "active"
  toJSON AllTasks     = String "all"

instance FromJSON ProxmoxTaskSource where
  parseJSON = withText "ProxmoxTaskSource" $ \case
    "archive" -> pure ArchiveTasks
    "active" -> pure ActiveTasks
    "all" -> pure AllTasks
    _anyOther -> fail "Invalid task source value"

data ProxmoxTask = ProxmoxTask
  { taskUpid      :: !Text
  , taskType      :: !(Maybe Text)
  , taskStatus    :: !(Maybe Text)
  , taskStartTime :: !(Maybe Int)
  , taskEndTime   :: !(Maybe Int)
  , taskUser      :: !Text
  , taskNode      :: !Text
  } deriving (Show, Eq, Ord)

instance ToJSON ProxmoxTask where
  toJSON (ProxmoxTask { .. }) = object
    [ "upid" .= taskUpid
    , "type" .= taskType
    , "status" .= taskStatus
    , "starttime" .= taskStartTime
    , "endtime" .= taskEndTime
    , "user" .= taskUser
    , "node" .= taskNode
    ]

instance FromJSON ProxmoxTask where
  parseJSON = withObject "ProxmoxTask" $ \v -> ProxmoxTask
    <$> v .:? "upid" .!= ""
    <*> v .:? "type"
    <*> v .:? "status"
    <*> nullMaybeWrapper (KV.lookup "starttime" v) intStringParser
    <*> nullMaybeWrapper (KV.lookup "endtime" v) intStringParser
    <*> v .: "user"
    <*> v .: "node"
