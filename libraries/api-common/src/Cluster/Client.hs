module Cluster.Client
  ( getPagedNodes
  , getNodeByName
  , createNode
  , deleteNodeByName
  , getDeployNode
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
  :<|> getDeployNode = client api
