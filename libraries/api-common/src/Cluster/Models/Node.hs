{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Cluster.Models.Node
  ( ClusterNode(..)
  ) where

import           Data.Aeson
import           Data.Text

data ClusterNode = ClusterNode
  { nodeName           :: !Text
  , nodeApiUrl         :: !Text
  , nodeIgnoreSSL      :: !Bool
  , nodeApiToken       :: !Text
  , nodeStartVMID      :: !(Maybe Int)
  , nodeAgentUrl       :: !Text
  , nodeAgentToken     :: !Text
  , nodeDisplayNetwork :: !Text
  , nodeMinDisplay     :: !Int
  , nodeMaxDisplay     :: !Int
  , nodeDisplayIP      :: !Text
  , nodeExcludedPorts  :: ![Int]
  } deriving (Show, Eq)

instance ToJSON ClusterNode where
  toJSON (ClusterNode { .. }) = object
    [ "name" .= nodeName
    , "apiUrl" .= nodeApiUrl
    , "ignoreSSL" .= nodeIgnoreSSL
    , "apiToken" .= nodeApiToken
    , "startVMID" .= nodeStartVMID
    , "agentUrl" .= nodeAgentUrl
    , "agentToken" .= nodeAgentToken
    , "displayNetwork" .= nodeDisplayNetwork
    , "minDisplay" .= nodeMinDisplay
    , "maxDisplay" .= nodeMaxDisplay
    , "displayIP" .= nodeDisplayIP
    , "excludedPorts" .= nodeExcludedPorts
    ]

instance FromJSON ClusterNode where
  parseJSON = withObject "ClusterNode" $ \v -> ClusterNode
    <$> v .: "name"
    <*> v .: "apiUrl"
    <*> v .: "ignoreSSL"
    <*> v .: "apiToken"
    <*> v .:? "startVMID"
    <*> v .: "agentUrl"
    <*> v .: "agentToken"
    <*> v .: "displayNetwork"
    <*> v .:? "minDisplay" .!= 1
    <*> v .:? "maxDisplay" .!= 5000
    <*> v .: "displayIP"
    <*> v .:? "excludedPorts" .!= []
