{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Config
  ( DeployConfig(..)
  , decodeDeployConfig
  , updateDeployConfigToken
  , emptyDeployConfig
  ) where

import           Data.Aeson
import           Data.Models.Config.Deploy
import           Data.Models.Config.DeployAgent
import           Data.Models.Config.Network
import           Data.Models.Config.Template
import           Data.Models.Config.VM
import           Data.Text                      (Text)
import qualified Data.Yaml                      as Y

data DeployConfig = DeployConfig
  { deployTemplates  :: ![ConfigTemplate]
  , deployParameters :: !DeployParams
  , deployVMs        :: ![ConfigVM]
  , deployNetworks   :: ![ConfigNetwork]
  , deployAgent      :: !(Maybe DeployAgentConfig)
  } deriving Show

instance FromJSON DeployConfig where
  parseJSON = withObject "DeployConfig" $ \v -> DeployConfig
    <$> v .:? "templates" .!= []
    <*> v .: "deploy"
    <*> v .:? "vms" .!= []
    <*> v .:? "networks" .!= []
    <*> v .:? "agent"

decodeDeployConfig :: FilePath -> IO (Either Y.ParseException DeployConfig)
decodeDeployConfig = Y.decodeFileEither

updateDeployConfigToken :: Maybe Text -> DeployConfig -> DeployConfig
updateDeployConfigToken (Just token) c@(DeployConfig {deployParameters = p@(DeployParams {deployToken = Nothing })}) = c { deployParameters = p { deployToken = Just token } }
updateDeployConfigToken _ p = p

-- used for tests, at least now
emptyDeployConfig :: DeployConfig
emptyDeployConfig = DeployConfig {deployTemplates=[], deployParameters=DeployParams {deployUrl="", deployToken=Nothing, deployNodeName="", deployIgnoreSSL=False, deployStartVMID = 100}, deployVMs=[], deployNetworks=[], deployAgent=Nothing}
