{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeOperators     #-}
module Deployment.Schema
  ( DeploymentAPI
  ) where

import           Api
import           Cluster.Models.Node
import qualified Data.Map                              as M
import           Data.Text
import           Deployment.Models.Deployment
import           Deployment.Models.Stats
import           Proxmox.Deploy.Models.Config.Template
import           Servant.API

type DeploymentTemplateCapture = Capture "DeploymentTemplateID" Int
type NodeNameCapture = Capture "NodeName" Text
type DeploymentInstanceCapture = Capture "DeploymentInstanceID" Text

type DeploymentAPI = "api" :> "deployment" :> "templates" :> QueryParam "page" Int :> AuthHeader :> Get '[JSON] (PagedResponse [ConfigTemplate])
  :<|> "api" :> "deployment" :> "templates" :> Capture "templateID" Int :> AuthHeader :> Delete '[JSON] ()
  :<|> "api" :> "deployment" :> "templates" :> ReqBody '[JSON] ConfigTemplate :> AuthHeader :> Post '[JSON] ()
  :<|> "api" :> "deployment" :> "deployments" :> QueryParam "page" Int :> AuthHeader :> Get '[JSON] (PagedResponse [DeploymentTemplate])
  :<|> "api" :> "deployment" :> "deployments" :> ReqBody '[JSON] DeploymentCreate :> AuthHeader :> Post '[JSON] ()
  :<|> "api" :> "deployment" :> "deployments" :> DeploymentTemplateCapture :> AuthHeader :> Get '[JSON] DeploymentTemplate
  :<|> "api" :> "deployment" :> "deployments" :> DeploymentTemplateCapture :> AuthHeader :> Delete '[JSON] ()
  :<|> "api" :> "deployment" :> "deployments" :> DeploymentTemplateCapture :> ReqBody '[JSON] DeploymentCreate :> AuthHeader :> Patch '[JSON] ()
  :<|> "api" :> "deployment" :> "deployments" :> DeploymentTemplateCapture :> "deploy" :> "group" :> QueryParam "group" Text :> AuthHeader :> Get '[JSON] ()
  :<|> "api" :> "deployment" :> "deployments" :> DeploymentTemplateCapture :> "destroy" :> "group" :> QueryParam "group" Text :> AuthHeader :> Get '[JSON] ()
  :<|> "api" :> "deployment" :> "deployments" :> DeploymentTemplateCapture :> "snapshot" :> "group" :> QueryParam "group" Text :> QueryParam "snapname" Text :> QueryFlag "delete" :> QueryFlag "rollback" :> AuthHeader :> Get '[JSON] ()
  :<|> "api" :> "deployment" :> "deployments" :> DeploymentTemplateCapture :> "power" :> "group" :> QueryParam "group" Text :> QueryFlag "on" :> AuthHeader :> Get '[JSON] ()
  :<|> "api" :> "deployment" :> "vmid" :> NodeNameCapture :> DeploymentInstanceCapture :> QueryParam "amount" Int :> AuthHeader :> Get '[JSON] [Int]
  :<|> "api" :> "deployment" :> "display" :> NodeNameCapture :> DeploymentInstanceCapture :> QueryParam "amount" Int :> AuthHeader :> Get '[JSON] [Int]
  :<|> "api" :> "deployment" :> "deployments" :> DeploymentTemplateCapture :> "instances" :> QueryParam "page" Int :> QueryParam "group" Text :> AuthHeader :> Get '[JSON] (PagedResponse [DeploymentInstanceBrief])
  :<|> "api" :> "deployment" :> "instances" :> "my" :> QueryParam "page" Int :> AuthHeader :> Get '[JSON] (PagedResponse [DeploymentInstanceBrief])
  :<|> "api" :> "deployment" :> "instances" :> DeploymentInstanceCapture :> AuthHeader :> Get '[JSON] DeploymentInstance
  :<|> "api" :> "deployment" :> "instances" :> DeploymentInstanceCapture :> "power" :> QueryFlag "on" :> AuthHeader :> Get '[JSON] ()
  :<|> "api" :> "deployment" :> "vm" :> Capture "VmPort" Text :> "power" :> AuthHeader :> Get '[JSON] PowerState
  :<|> "api" :> "deployment" :> "vm" :> Capture "VmPort" Text :> "power" :> "switch" :> AuthHeader :> Get '[JSON] PowerState
  :<|> "api" :> "deployment" :> "vm" :> Capture "VmPort" Text :> "networks" :> AuthHeader :> Get '[JSON] (M.Map String String)
  :<|> "api" :> "deployment" :> "vmport" :> "access" :> Header' '[Required] "X-VM-PORT" Text :> AuthHeader :> Get '[JSON] ()
  :<|> "api" :> "deployment" :> "deployments" :> DeploymentTemplateCapture :> "instances" :> "stats" :> QueryParam "group" Text :> AuthHeader :> Get '[JSON] DeploymentStats
  :<|> "api" :> "deployment" :> "instances" :> DeploymentInstanceCapture :> "destroy" :> AuthHeader :> Get '[JSON] ()
  :<|> "api" :> "deployment" :> "instances" :> DeploymentInstanceCapture :> "snapshot" :> QueryParam "snapname" Text :> QueryFlag "delete" :> QueryFlag "rollback" :> AuthHeader :> Get '[JSON] ()
  :<|> "api" :> "deployment" :> "network" :> NodeNameCapture :> Capture "DeploymentInstanceID" Text :> QueryParam "amount" Int :> AuthHeader :> Get '[JSON] [String]
  :<|> "api" :> "deployment" :> "instances" :> Capture "DeploymentInstanceID" Text :> ReqBody '[JSON] DeploymentPatch :> AuthHeader :> Patch '[JSON] ()
  :<|> "api" :> "deployment" :> "templates" :> "names" :> "list" :> ReqBody '[JSON] [Text] :> AuthHeader :> Post '[JSON] [ConfigTemplate]
  :<|> "api" :> "deployment" :> "instances" :> DeploymentInstanceCapture :> AuthHeader :> Delete '[JSON] ()
  :<|> "api" :> "deployment" :> "vm" :> "allocations" :> "amount" :> "undeployed" :> AuthHeader :> Get '[JSON] (M.Map Text Int)
