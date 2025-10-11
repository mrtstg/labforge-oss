{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Config.DeployAgent
  ( DeployAgentConfig(..)
  ) where

import           Data.Aeson
import           Data.Text

data DeployAgentConfig = DeployAgentConfig
  { configAgentURL            :: !Text
  , configAgentToken          :: !Text
  , configAgentDisplayNetwork :: !Text
  } deriving (Show, Eq)

instance FromJSON DeployAgentConfig where
  parseJSON = withObject "DeployAgentConfig" $ \v -> DeployAgentConfig
    <$> v .: "url"
    <*> v .: "token"
    <*> v .:? "display_network" .!= "0.0.0.0"
