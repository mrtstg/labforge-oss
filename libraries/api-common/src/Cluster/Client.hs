module Cluster.Client
  ( getPagedNodes
  , getNodeByName
  , createNode
  , deleteNodeByName
  , getDeployNode
  , getWebsockifyConfig
  ) where

import           Cluster.Schema
import           Servant
import           Servant.Client

api :: Proxy ClusterManagerAPI
api = Proxy

getPagedNodes
  :<|> getNodeByName
  :<|> createNode
  :<|> deleteNodeByName
  :<|> getDeployNode
  :<|> getWebsockifyConfig = client api
