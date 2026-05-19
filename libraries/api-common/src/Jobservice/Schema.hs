{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeOperators     #-}
module Jobservice.Schema
  ( JobserviceAPI
  ) where

import           Api
import           Data.Text
import           Jobservice.Models
import           Servant.API

type JobserviceAPI = "api" :> "jobservice" :> "message" :> ReqBody '[JSON] JobserviceTask :> AuthHeader :> Post '[JSON] JobserviceTaskResponse
  :<|> "api" :> "jobservice" :> "images" :> "held" :> AuthHeader :> Get '[JSON] [String]
  :<|> "api" :> "jobservice" :> "image" :> Capture "imageName" Text :> "usage" :> AuthHeader :> Get '[JSON] [JobserviceImageUsageData]
  :<|> "api" :> "jobservice" :> "deployment" :> Capture "deploymentId" Text :> "lock" :> Capture "lockType" JobserviceLockType :> AuthHeader :> Get '[JSON] Bool
  :<|> "api" :> "jobservice" :> "task" :> Capture "taskId" Text :> AuthHeader :> Delete '[JSON] ()
  :<|> "api" :> "jobservice" :> "task" :> Capture "taskId" Text :> "cancel" :> AuthHeader :> Get '[JSON] Bool
  :<|> "api" :> "jobservice" :> "task" :> Capture "taskId" Text :> "cancel" :> AuthHeader :> Post '[JSON] ()
  :<|> "api" :> "jobservice" :> "task" :> Capture "taskId" Text :> AuthHeader :> Get '[JSON] JobserviceTask
  :<|> "api" :> "jobservice" :> "task" :> QueryParam "page" Int :> AuthHeader :> Get '[JSON] (PagedResponse [JobserviceTask])
