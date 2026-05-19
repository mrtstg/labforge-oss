module Jobservice.Client
  ( insertJobserviceMessage
  , getHeldImages
  , getImageUsage
  , isDeploymentLocked
  , insertJobserviceMessage'
  , deleteTask
  , getTaskCancel
  , cancelTask
  , getTask
  , getPagedTasks
  ) where

import           Api.Keycloak.Models
import           Jobservice.Models
import           Jobservice.Schema
import           Servant
import           Servant.Client

api :: Proxy JobserviceAPI
api = Proxy

insertJobserviceMessage' :: JobserviceMessage -> Maybe JobserviceMessageMeta -> BearerWrapper -> ClientM JobserviceTaskResponse
insertJobserviceMessage' msg meta = insertJobserviceMessage (JobserviceTask Nothing meta msg)

insertJobserviceMessage
  :<|> getHeldImages
  :<|> getImageUsage
  :<|> isDeploymentLocked
  :<|> deleteTask
  :<|> getTaskCancel
  :<|> cancelTask
  :<|> getTask
  :<|> getPagedTasks = client api
