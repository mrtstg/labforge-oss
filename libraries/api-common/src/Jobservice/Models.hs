{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Jobservice.Models
  ( jobserviceUsedImagesKey
  , JobserviceMessage(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import           Data.Text         (Text)

jobserviceUsedImagesKey = "jobservice-used-images"

data JobserviceMessage = JobserviceUpdateUsedImages {}
                       | JobserviceAllocateNode { deploymentId :: !Text }
                       | JobserviceDeployInstance { deploymentId :: !Text }
                       | JobserviceDestroyInstance { deploymentId :: !Text }
                       | JobserviceSnapshot { deploymentId :: !Text, deploymentSnapshot :: !Text, deploymentDelete :: !Bool }
                       | JobserviceRollback { deploymentId :: !Text, deploymentSnapshot :: !Text }
                       | JobservicePower { deploymentId :: !Text, deploymentPower :: !Bool } deriving (Show, Eq)

instance ToJSON JobserviceMessage where
  toJSON (JobserviceUpdateUsedImages {}) = object ["type" .= String "updateImages"]
  toJSON (JobserviceAllocateNode { .. }) = object ["type" .= String "allocateNode", "deploymentId" .= deploymentId]
  toJSON (JobserviceDeployInstance { .. }) = object ["type" .= String "deployInstance", "deploymentId" .= deploymentId]
  toJSON (JobserviceDestroyInstance { .. }) = object ["type" .= String "destroyInstance", "deploymentId" .= deploymentId]
  toJSON (JobserviceSnapshot { .. }) = object [ "type" .= String "snapshotInstance", "deploymentId" .= deploymentId, "snapshot" .= deploymentSnapshot, "delete" .= deploymentDelete ]
  toJSON (JobserviceRollback { .. }) = object [ "type" .= String "rollbackInstance", "deploymentId" .= deploymentId, "snapshot" .= deploymentSnapshot ]
  toJSON (JobservicePower { .. }) = object [ "type" .= String "powerInstance", "deploymentId" .= deploymentId, "power" .= deploymentPower ]

instance FromJSON JobserviceMessage where
  parseJSON = withObject "JobserviceMessage" $ \v -> case KM.lookup "type" v of
    (Just (String "updateImages")) -> pure JobserviceUpdateUsedImages {}
    (Just (String "allocateNode")) -> JobserviceAllocateNode
      <$> v .: "deploymentId"
    (Just (String "deployInstance")) -> JobserviceDeployInstance
      <$> v .: "deploymentId"
    (Just (String "destroyInstance")) -> JobserviceDestroyInstance
      <$> v .: "deploymentId"
    (Just (String "snapshotInstance")) -> JobserviceSnapshot
      <$> v .: "deploymentId"
      <*> v .: "snapshot"
      <*> v .: "delete"
    (Just (String "rollbackInstance")) -> JobserviceRollback
      <$> v .: "deploymentId"
      <*> v .: "snapshot"
    (Just (String "powerInstance")) -> JobservicePower
      <$> v .: "deploymentId"
      <*> v .: "power"
    _anyOther                      -> fail "Invalid task type!"
