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
                       | JobserviceAllocateNode { deploymentId :: !Text } deriving (Show, Eq)

instance ToJSON JobserviceMessage where
  toJSON (JobserviceUpdateUsedImages {}) = object ["type" .= String "updateImages"]
  toJSON (JobserviceAllocateNode { .. }) = object ["type" .= String "allocateNode", "deploymentId" .= deploymentId]

instance FromJSON JobserviceMessage where
  parseJSON = withObject "JobserviceMessage" $ \v -> case KM.lookup "type" v of
    (Just (String "updateImages")) -> pure JobserviceUpdateUsedImages {}
    (Just (String "allocateNode")) -> JobserviceAllocateNode
      <$> v .: "deploymentId"
    _anyOther                      -> fail "Invalid task type!"
