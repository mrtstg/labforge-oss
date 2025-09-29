{-# LANGUAGE OverloadedStrings #-}
module Jobservice.Models
  ( jobserviceUsedImagesKey
  , JobserviceMessage(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KM

jobserviceUsedImagesKey = "jobservuce-used-images"

data JobserviceMessage = JobserviceUpdateUsedImages {} deriving (Show, Eq)

instance ToJSON JobserviceMessage where
  toJSON (JobserviceUpdateUsedImages {}) = object ["type" .= String "updateImages"]

instance FromJSON JobserviceMessage where
  parseJSON = withObject "JobserviceMessage" $ \v -> case KM.lookup "type" v of
    (Just (String "updateImages")) -> pure JobserviceUpdateUsedImages {}
    _anyOther                      -> fail "Invalid task type!"
