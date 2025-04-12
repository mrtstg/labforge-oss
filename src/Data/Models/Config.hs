{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Config 
  ( DeployConfig(..)
  , decodeDeployConfig
  ) where

import Data.Models.Config.Template
import Data.Aeson
import qualified Data.Yaml as Y

data DeployConfig = DeployConfig 
  { deployTemplates :: ![ConfigTemplate]
  } deriving Show

instance FromJSON DeployConfig where
  parseJSON = withObject "DeployConfig" $ \v -> DeployConfig
    <$> v .: "templates"

decodeDeployConfig :: FilePath -> IO (Either Y.ParseException DeployConfig)
decodeDeployConfig = Y.decodeFileEither
