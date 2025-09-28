{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeOperators     #-}
module Cluster.Schema
  ( ClusterManagerAPI
  ) where

import           Api
import           Cluster.Models.Node
import           Data.Text
import           Servant.API

type NodeNameCapture = Capture "nodeName" Text

type ClusterManagerAPI = "api" :> "cluster" :> "nodes" :> AuthHeader :> QueryParam "page" Int :> Get '[JSON] (PagedResponse [ClusterNode])
  :<|> "api" :> "cluster" :> "nodes" :> NodeNameCapture :> AuthHeader :> Get '[JSON] ClusterNode
  :<|> "api" :> "cluster" :> "nodes" :> ReqBody '[JSON] ClusterNode :> AuthHeader :> Post '[JSON] ()
  :<|> "api" :> "cluster" :> "nodes" :> NodeNameCapture :> AuthHeader :> Delete '[JSON] ()
  :<|> "api" :> "cluster" :> "deploy" :> "node" :> AuthHeader :> Get '[JSON] ClusterNode
  :<|> "api" :> "cluster" :> "websockify" :> "config" :> Get '[PlainText] Text
