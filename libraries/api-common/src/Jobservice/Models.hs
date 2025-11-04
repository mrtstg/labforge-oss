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
                       | JobserviceDestroyInstance { deploymentId :: !Text } deriving (Show, Eq)

instance ToJSON JobserviceMessage where
  toJSON (JobserviceUpdateUsedImages {}) = object ["type" .= String "updateImages"]
  toJSON (JobserviceAllocateNode { .. }) = object ["type" .= String "allocateNode", "deploymentId" .= deploymentId]
  toJSON (JobserviceDeployInstance { .. }) = object ["type" .= String "deployInstance", "deploymentId" .= deploymentId]
  toJSON (JobserviceDestroyInstance { .. }) = object ["type" .= String "destroyInstance", "deploymentId" .= deploymentId]

instance FromJSON JobserviceMessage where
  parseJSON = withObject "JobserviceMessage" $ \v -> case KM.lookup "type" v of
    (Just (String "updateImages")) -> pure JobserviceUpdateUsedImages {}
    (Just (String "allocateNode")) -> JobserviceAllocateNode
      <$> v .: "deploymentId"
    (Just (String "deployInstance")) -> JobserviceDeployInstance
      <$> v .: "deploymentId"
    (Just (String "destroyInstance")) -> JobserviceDestroyInstance
      <$> v .: "deploymentId"
    _anyOther                      -> fail "Invalid task type!"
