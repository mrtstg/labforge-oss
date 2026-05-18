{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Jobservice.Models
  ( jobserviceUsedImagesKey
  , jobserviceUsedImageKey
  , JobserviceMessage(..)
  , JobserviceImageUsageData(..)
  , JobserviceLockType(..)
  , jobserviceLockKey
  , JobserviceMessageMeta(..)
  , JobserviceTask(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import           Data.Text         (Text)
import           Servant.API

data JobserviceLockType = AnyLock | GenericLock | SnapshotLock | PowerLock deriving (Show, Eq, Ord)

instance ToHttpApiData JobserviceLockType where
  toUrlPiece AnyLock      = "any"
  toUrlPiece GenericLock  = "generic"
  toUrlPiece SnapshotLock = "snapshot"
  toUrlPiece PowerLock    = "power"

instance FromHttpApiData JobserviceLockType where
  parseUrlPiece "any"      = pure AnyLock
  parseUrlPiece "generic"  = pure AnyLock
  parseUrlPiece "snapshot" = pure AnyLock
  parseUrlPiece "power"    = pure AnyLock
  parseUrlPiece _          = Left "Invalid lock type"

jobserviceLockKey :: JobserviceLockType -> Text -> Text
jobserviceLockKey GenericLock  = ("deployment_action_" <>)
jobserviceLockKey AnyLock      = jobserviceLockKey GenericLock
jobserviceLockKey SnapshotLock = ("deployment_snapshot_" <>)
jobserviceLockKey PowerLock    = ("deployment_power_task_" <>)

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

data JobserviceMessageMeta = JobserviceMessageMeta
  { deploymentId :: !Text
  , templateId   :: !Int
  , actionGroup  :: !(Maybe Text)
  , targetUserId :: !(Maybe Text)
  , authorId     :: !(Maybe Text)
  } deriving (Show, Eq, Ord)

instance ToJSON JobserviceMessageMeta where
  toJSON (JobserviceMessageMeta { .. }) = object
    [ "deployment" .= deploymentId
    , "template" .= templateId
    , "group" .= actionGroup
    , "user" .= targetUserId
    , "author" .= authorId
    ]

instance FromJSON JobserviceMessageMeta where
  parseJSON = withObject "JobserviceMessageMeta" $ \v -> JobserviceMessageMeta
    <$> v .: "deployment"
    <*> v .: "template"
    <*> v .: "group"
    <*> v .: "user"
    <*> v .: "author"

data JobserviceTask = JobserviceTask (Maybe JobserviceMessageMeta) JobserviceMessage deriving (Show, Eq)

instance FromJSON JobserviceTask where
  parseJSON = withObject "JobserviceTask" $ \v -> JobserviceTask
    <$> v .:? "meta"
    <*> v .: "data"

instance ToJSON JobserviceTask where
  toJSON (JobserviceTask meta data') = object ["meta" .= meta, "data" .= data']

data JobserviceMessage = JobserviceUpdateUsedImages {}
                       | JobserviceAllocateNode  {}
                       | JobserviceDeployInstance {}
                       | JobserviceDestroyInstance {}
                       | JobserviceSnapshot { deploymentSnapshot :: !Text, deploymentDelete :: !Bool, deploymentMask :: !Text, deploymentSnapshotComment :: !Text }
                       | JobserviceRollback { deploymentSnapshot :: !Text, deploymentMask :: !Text }
                       | JobservicePower {  deploymentPower :: !Bool, deploymentMask :: !Text } deriving (Show, Eq)

instance ToJSON JobserviceMessage where
  toJSON (JobserviceUpdateUsedImages {}) = object ["type" .= String "updateImages"]
  toJSON (JobserviceAllocateNode {}) = object ["type" .= String "allocateNode"]
  toJSON (JobserviceDeployInstance {}) = object ["type" .= String "deployInstance"]
  toJSON (JobserviceDestroyInstance {}) = object ["type" .= String "destroyInstance"]
  toJSON (JobserviceSnapshot { .. }) = object [ "type" .= String "snapshotInstance", "snapshot" .= deploymentSnapshot, "delete" .= deploymentDelete, "mask" .= deploymentMask, "comment" .= deploymentSnapshotComment ]
  toJSON (JobserviceRollback { .. }) = object [ "type" .= String "rollbackInstance", "snapshot" .= deploymentSnapshot, "mask" .= deploymentMask ]
  toJSON (JobservicePower { .. }) = object [ "type" .= String "powerInstance", "power" .= deploymentPower, "mask" .= deploymentMask ]

instance FromJSON JobserviceMessage where
  parseJSON = withObject "JobserviceMessage" $ \v -> case KM.lookup "type" v of
    (Just (String "updateImages")) -> pure JobserviceUpdateUsedImages {}
    (Just (String "allocateNode")) -> pure JobserviceAllocateNode
    (Just (String "deployInstance")) -> pure JobserviceDeployInstance
    (Just (String "destroyInstance")) -> pure JobserviceDestroyInstance
    (Just (String "snapshotInstance")) -> JobserviceSnapshot
      <$> v .: "snapshot"
      <*> v .:? "delete" .!= False
      <*> v .: "mask"
      <*> v .:? "comment" .!= ""
    (Just (String "rollbackInstance")) -> JobserviceRollback
      <$> v .: "snapshot"
      <*> v .: "mask"
    (Just (String "powerInstance")) -> JobservicePower
      <$> v .: "power"
      <*> v .: "mask"
    _anyOther                      -> fail "Invalid task type!"
