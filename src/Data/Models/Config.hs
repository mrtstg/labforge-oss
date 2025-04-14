{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Config 
  ( DeployConfig(..)
  , decodeDeployConfig
  , updateDeployConfigToken
  ) where

import Data.Models.Config.Deploy
import Data.Models.Config.Template
import Data.Models.Config.VM
import Data.Aeson
import qualified Data.Yaml as Y
import Data.Text (Text)

data DeployConfig = DeployConfig 
  { deployTemplates :: ![ConfigTemplate]
  , deployParameters :: !DeployParams
  , deployVMs :: ![ConfigVM]
  } deriving Show

instance FromJSON DeployConfig where
  parseJSON = withObject "DeployConfig" $ \v -> DeployConfig
    <$> v .:? "templates" .!= []
    <*> v .: "deploy"
    <*> v .:? "vms" .!= []

decodeDeployConfig :: FilePath -> IO (Either Y.ParseException DeployConfig)
decodeDeployConfig = Y.decodeFileEither

updateDeployConfigToken :: Maybe Text -> DeployConfig -> DeployConfig
updateDeployConfigToken (Just token) c@(DeployConfig {deployParameters = p@(DeployParams {deployToken = Nothing })}) = c { deployParameters = p { deployToken = Just token } }
updateDeployConfigToken _ p = p
