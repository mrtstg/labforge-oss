module Jobservice.Client
  ( insertJobserviceMessage
  , getHeldImages
  , getImageUsage
  ) where

import           Jobservice.Schema
import           Servant
import           Servant.Client

api :: Proxy JobserviceAPI
api = Proxy

insertJobserviceMessage
  :<|> getHeldImages
  :<|> getImageUsage = client api
