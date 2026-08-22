module Cluster.Client
  ( getPagedNodes
  , getNodeByName
  , createNode
  , deleteNodeByName
  , getDeployNode
  , lookupVMNode
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
  :<|> lookupVMNode = client api
