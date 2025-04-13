{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Config.Deploy 
  ( DeployParams(..)
  ) where

import Data.Aeson
import Data.Text

data DeployParams = DeployParams
  { deployNodeName :: !Text
  , deployToken :: !(Maybe Text)
  , deployUrl :: !Text
  , deployIgnoreSSL :: !Bool
  } deriving Show

instance FromJSON DeployParams where
  parseJSON = withObject "DeployParams" $ \v -> DeployParams
    <$> v .: "node"
    <*> v .:? "token"
    <*> v .: "url"
    <*> v .:? "ignore_ssl" .!= False
