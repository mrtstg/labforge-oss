module Jobservice.Client
  ( insertJobserviceMessage
  , getHeldImages
  , getImageUsage
  , isDeploymentLocked
  , insertJobserviceMessage'
  ) where

import           Api.Keycloak.Models
import           Jobservice.Models
import           Jobservice.Schema
import           Servant
import           Servant.Client

api :: Proxy JobserviceAPI
api = Proxy

insertJobserviceMessage' :: JobserviceMessage -> Maybe JobserviceMessageMeta -> BearerWrapper -> ClientM ()
insertJobserviceMessage' msg meta = insertJobserviceMessage (JobserviceTask Nothing meta msg)

insertJobserviceMessage
  :<|> getHeldImages
  :<|> getImageUsage
  :<|> isDeploymentLocked = client api
