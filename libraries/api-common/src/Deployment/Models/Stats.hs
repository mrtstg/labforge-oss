{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Deployment.Models.Stats
  ( DeploymentStats(..)
  ) where

import           Data.Aeson

data DeploymentStats = DeploymentStats
  { deployedAmount   :: !Int
  , deployingAmount  :: !Int
  , destroyingAmount :: !Int
  , createdAmount    :: !Int
  , failedAmount     :: !Int
  } deriving (Show, Eq)

instance ToJSON DeploymentStats where
  toJSON (DeploymentStats { .. }) = object
    [ "deployed" .= deployedAmount
    , "deploying" .= deployingAmount
    , "destroying" .= destroyingAmount
    , "created" .= createdAmount
    , "failed" .= failedAmount
    ]

instance FromJSON DeploymentStats where
  parseJSON = withObject "DeploymentStats" $ \v -> DeploymentStats
    <$> v .: "deployed"
    <*> v .: "deploying"
    <*> v .: "destroying"
    <*> v .: "created"
    <*> v .: "failed"
