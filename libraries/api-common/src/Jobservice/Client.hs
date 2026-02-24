module Jobservice.Client
  ( insertJobserviceMessage
  , getHeldImages
  , getImageUsage
  , isDeploymentLocked
  ) where

import           Jobservice.Schema
import           Servant
import           Servant.Client

api :: Proxy JobserviceAPI
api = Proxy

insertJobserviceMessage
  :<|> getHeldImages
  :<|> getImageUsage
  :<|> isDeploymentLocked = client api
