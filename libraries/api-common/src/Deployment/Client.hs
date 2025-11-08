{-# LANGUAGE DataKinds #-}
module Deployment.Client
  ( getPagedTemplates
  , deleteTemplate
  , createTemplate
  , getPagedDeploymentTemplates
  , createDeploymentTemplate
  , getDeploymentTemplate
  , deleteDeploymentTemplate
  , patchDeploymentTemplate
  , callGroupDeployment
  , requestDeploymentVMID
  , requestDeploymentDisplay
  , getDeploymentTemplateInstances
  , getMyTemplateInstances
  , getDeploymentInstance
  , getVMPortPower
  , switchVMPortPower
  , getVMPortNetworks
  , callGroupDestroy
  , callGroupPower
  , setDeploymentInstancePower
  , checkVMPortAccess
  , getDeploymentInstancesStats
  , callInstanceDestroy
  , callGroupSnapshot
  , callInstanceSnapshot
  , requestDeploymentNetwork
  , patchDeploymentInstance
  , getTemplatesListByNames
  , deleteDeploymentInstance
  , getUndeployedVMAmount
  ) where

import           Data.Proxy
import           Deployment.Schema
import           Servant
import           Servant.Client

api :: Proxy DeploymentAPI
api = Proxy

getPagedTemplates
  :<|> deleteTemplate
  :<|> createTemplate
  :<|> getPagedDeploymentTemplates
  :<|> createDeploymentTemplate
  :<|> getDeploymentTemplate
  :<|> deleteDeploymentTemplate
  :<|> patchDeploymentTemplate
  :<|> callGroupDeployment
  :<|> callGroupDestroy
  :<|> callGroupSnapshot
  :<|> callGroupPower
  :<|> requestDeploymentVMID
  :<|> requestDeploymentDisplay
  :<|> getDeploymentTemplateInstances
  :<|> getMyTemplateInstances
  :<|> getDeploymentInstance
  :<|> setDeploymentInstancePower
  :<|> getVMPortPower
  :<|> switchVMPortPower
  :<|> getVMPortNetworks
  :<|> checkVMPortAccess
  :<|> getDeploymentInstancesStats
  :<|> callInstanceDestroy
  :<|> callInstanceSnapshot
  :<|> requestDeploymentNetwork
  :<|> patchDeploymentInstance
  :<|> getTemplatesListByNames
  :<|> deleteDeploymentInstance
  :<|> getUndeployedVMAmount = client api
