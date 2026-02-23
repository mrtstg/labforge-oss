{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Jobservice.Models
  ( jobserviceUsedImagesKey
  , jobserviceUsedImageKey
  , JobserviceMessage(..)
  , JobserviceImageUsageData(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import           Data.Text         (Text)

jobserviceUsedImageKey imageName = "jobservice-used-" <> imageName <> "-at"
jobserviceUsedImagesKey = "jobservice-used-images"

data JobserviceImageUsageData = JobserviceImageUsageData
  { usedImageDeploymentName     :: !Text
  , usedImageDeploymentUserId   :: !Text
  , usedImageDeploymentUserName :: !Text
  , usedImageDeploymentId       :: !Int
  } deriving (Show, Eq)

instance FromJSON JobserviceImageUsageData where
  parseJSON = withObject "JobserviceImageUsageData" $ \v -> JobserviceImageUsageData
    <$> v .: "name"
    <*> v .: "userId"
    <*> v .: "userName"
    <*> v .: "deploymentId"

instance ToJSON JobserviceImageUsageData where
  toJSON (JobserviceImageUsageData { .. }) = object
    [ "name" .= usedImageDeploymentName
    , "userId" .= usedImageDeploymentUserId
    , "userName" .= usedImageDeploymentUserName
    , "deploymentId" .= usedImageDeploymentId
    ]

data JobserviceMessage = JobserviceUpdateUsedImages {}
                       | JobserviceAllocateNode { deploymentId :: !Text }
                       | JobserviceDeployInstance { deploymentId :: !Text }
                       | JobserviceDestroyInstance { deploymentId :: !Text }
                       | JobserviceSnapshot { deploymentId :: !Text, deploymentSnapshot :: !Text, deploymentDelete :: !Bool, deploymentMask :: !Text, deploymentSnapshotComment :: !Text }
                       | JobserviceRollback { deploymentId :: !Text, deploymentSnapshot :: !Text, deploymentMask :: !Text }
                       | JobservicePower { deploymentId :: !Text, deploymentPower :: !Bool, deploymentMask :: !Text } deriving (Show, Eq)

instance ToJSON JobserviceMessage where
  toJSON (JobserviceUpdateUsedImages {}) = object ["type" .= String "updateImages"]
  toJSON (JobserviceAllocateNode { .. }) = object ["type" .= String "allocateNode", "deploymentId" .= deploymentId]
  toJSON (JobserviceDeployInstance { .. }) = object ["type" .= String "deployInstance", "deploymentId" .= deploymentId]
  toJSON (JobserviceDestroyInstance { .. }) = object ["type" .= String "destroyInstance", "deploymentId" .= deploymentId]
  toJSON (JobserviceSnapshot { .. }) = object [ "type" .= String "snapshotInstance", "deploymentId" .= deploymentId, "snapshot" .= deploymentSnapshot, "delete" .= deploymentDelete, "mask" .= deploymentMask, "comment" .= deploymentSnapshotComment ]
  toJSON (JobserviceRollback { .. }) = object [ "type" .= String "rollbackInstance", "deploymentId" .= deploymentId, "snapshot" .= deploymentSnapshot, "mask" .= deploymentMask ]
  toJSON (JobservicePower { .. }) = object [ "type" .= String "powerInstance", "deploymentId" .= deploymentId, "power" .= deploymentPower, "mask" .= deploymentMask ]

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
      <*> v .:? "delete" .!= False
      <*> v .: "mask"
      <*> v .:? "comment" .!= ""
    (Just (String "rollbackInstance")) -> JobserviceRollback
      <$> v .: "deploymentId"
      <*> v .: "snapshot"
      <*> v .: "mask"
    (Just (String "powerInstance")) -> JobservicePower
      <$> v .: "deploymentId"
      <*> v .: "power"
      <*> v .: "mask"
    _anyOther                      -> fail "Invalid task type!"
