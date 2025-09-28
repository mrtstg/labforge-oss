{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Deployment.Models.Deployment
  ( DeploymentCreate(..)
  , DeploymentTemplate(..)
  , DeploymentInstance(..)
  , DeploymentInstanceBrief(..)
  , PowerState(..)
  , DeploymentStatus(..)
  ) where

import           Data.Aeson
import qualified Data.Map                        as M
import           Data.Text
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.VM

newtype PowerState = PowerState Bool deriving (Show, Eq)

instance ToJSON PowerState where
  toJSON (PowerState v) = object ["power" .= v]

instance FromJSON PowerState where
  parseJSON = withObject "PowerState" $ \v -> PowerState <$> v .: "power"

data DeploymentCreate = DeploymentCreate
  { reqTitle            :: !Text
  , reqVMs              :: ![ConfigVM]
  , reqAvailableVMs     :: ![Text]
  , reqExistingNetworks :: ![Text]
  } deriving (Show, Eq)

instance ToJSON DeploymentCreate where
  toJSON (DeploymentCreate { .. }) = object
    [ "title" .= reqTitle
    , "vms" .= reqVMs
    , "availableVMs" .= reqAvailableVMs
    , "existingNetworks" .= reqExistingNetworks
    ]

instance FromJSON DeploymentCreate where
  parseJSON = withObject "DeploymentCreate" $ \v -> DeploymentCreate
    <$> v .: "title"
    <*> v .: "vms"
    <*> v .: "availableVMs"
    <*> v .: "existingNetworks"

data DeploymentTemplate = DeploymentTemplate
  { templateId               :: !Int
  , templateOwner            :: !Text
  , templateTitle            :: !Text
  , templateVMs              :: ![ConfigVM]
  , templateAvaiableVMs      :: ![Text]
  , templateExistingNetworks :: ![Text]
  } deriving (Show, Eq)

instance FromJSON DeploymentTemplate where
  parseJSON = withObject "DeploymentTemplate" $ \v -> DeploymentTemplate
    <$> v .: "id"
    <*> v .: "owner"
    <*> v .: "title"
    <*> v .: "vms"
    <*> v .: "availableVMs"
    <*> v .: "existingNetworks"

instance ToJSON DeploymentTemplate where
  toJSON (DeploymentTemplate { .. }) = object
    [ "id" .= templateId
    , "owner" .= templateOwner
    , "title" .= templateTitle
    , "vms" .= templateVMs
    , "availableVMs" .= templateAvaiableVMs
    , "existingNetworks" .= templateExistingNetworks
    ]

data DeploymentStatus = Created | Deploying | Deployed | Destroying | Failed deriving (Show, Eq)

instance ToJSON DeploymentStatus where
  toJSON Deploying  = "deploying"
  toJSON Deployed   = "deployed"
  toJSON Destroying = "destroying"
  toJSON Created    = "created"
  toJSON Failed     = "failed"

instance FromJSON DeploymentStatus where
  parseJSON (String "deploying")  = pure Deploying
  parseJSON (String "deployed")   = pure Deployed
  parseJSON (String "destroying") = pure Destroying
  parseJSON (String "created")    = pure Created
  parseJSON (String "failed")     = pure Failed
  parseJSON _                     = fail "Invalid deployment status value"

data DeploymentInstanceBrief = DeploymentInstanceBrief
  { briefDeploymentTitle  :: !Text
  , briefDeploymentId     :: !Text
  , briefDeploymentStatus :: !DeploymentStatus
  , briefDeploymentUser   :: !Text
  } deriving (Show, Eq)

instance ToJSON DeploymentInstanceBrief where
  toJSON (DeploymentInstanceBrief { .. }) = object
    [ "id" .= briefDeploymentId
    , "title" .= briefDeploymentTitle
    , "status" .= briefDeploymentStatus
    , "userId" .= briefDeploymentUser
    ]

instance FromJSON DeploymentInstanceBrief where
  parseJSON = withObject "DeploymentInstanceBrief" $ \v -> DeploymentInstanceBrief
    <$> v .: "title"
    <*> v .: "id"
    <*> v .: "status"
    <*> v .: "userId"

data DeploymentInstance = DeploymentInstance
  { instanceTitle        :: !Text
  , instanceOf           :: !Int
  , instanceDeployConfig :: !(Maybe DeployConfig)
  , instanceNetworkMap   :: !(Maybe (M.Map String String))
  , instanceLogs         :: ![Text]
  , instanceVMLinks      :: !(M.Map Text Text)
  , instanceVMPower      :: !(M.Map Text Bool)
  , instanceState        :: !DeploymentStatus
  , instanceUser         :: !Text
  } deriving (Show)

instance ToJSON DeploymentInstance where
  toJSON (DeploymentInstance { .. }) = object
    [ "title" .= instanceTitle
    , "parentTemplateId" .= instanceOf
    , "deployConfig" .= instanceDeployConfig
    , "networkMap" .= instanceNetworkMap
    , "logs" .= instanceLogs
    , "vmLinks" .= instanceVMLinks
    , "state" .= instanceState
    , "userId" .= instanceUser
    , "vmPower" .= instanceVMPower
    ]

instance FromJSON DeploymentInstance where
  parseJSON = withObject "DeploymentInstance" $ \v -> DeploymentInstance
    <$> v .: "title"
    <*> v .: "parentTemplateId"
    <*> v .:? "deployConfig"
    <*> v .:? "networkMap"
    <*> v .:? "logs" .!= []
    <*> v .:? "vmLinks" .!= M.empty
    <*> v .:? "vmPower" .!= M.empty
    <*> v .: "state"
    <*> v .: "userId"
