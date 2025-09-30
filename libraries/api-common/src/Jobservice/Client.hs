module Jobservice.Client
  ( insertJobserviceMessage
  , getHeldImages
  ) where

import           Jobservice.Schema
import           Servant
import           Servant.Client

api :: Proxy JobserviceAPI
api = Proxy

insertJobserviceMessage
  :<|> getHeldImages = client api
