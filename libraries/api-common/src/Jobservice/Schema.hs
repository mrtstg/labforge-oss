{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeOperators     #-}
module Jobservice.Schema
  ( JobserviceAPI
  ) where

import           Api
import           Jobservice.Models
import           Servant.API

type JobserviceAPI = "api" :> "jobservice" :> "message" :> ReqBody '[JSON] JobserviceMessage :> AuthHeader :> Post '[JSON] ()
  :<|> "api" :> "jobservice" :> "images" :> "held" :> AuthHeader :> Get '[JSON] [String]
