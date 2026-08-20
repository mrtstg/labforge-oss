{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Cluster.Models.Node
  ( ClusterNode(..)
  ) where

import           Data.Aeson
import           Data.Text

data ClusterNode = ClusterNode
  { nodeName      :: !Text
  , nodeApiUrl    :: !Text
  , nodeIgnoreSSL :: !Bool
  , nodeApiToken  :: !Text
  , nodeStartVMID :: !(Maybe Int)
  } deriving (Show, Eq)

instance ToJSON ClusterNode where
  toJSON (ClusterNode { .. }) = object
    [ "name" .= nodeName
    , "apiUrl" .= nodeApiUrl
    , "ignoreSSL" .= nodeIgnoreSSL
    , "apiToken" .= nodeApiToken
    , "startVMID" .= nodeStartVMID
    ]

instance FromJSON ClusterNode where
  parseJSON = withObject "ClusterNode" $ \v -> ClusterNode
    <$> v .: "name"
    <*> v .: "apiUrl"
    <*> v .: "ignoreSSL"
    <*> v .: "apiToken"
    <*> v .:? "startVMID"
