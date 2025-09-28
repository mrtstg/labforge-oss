{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}
module Kroki.Schema
  ( RenderAPI
  ) where

import           Api
import           Data.Text (Text)
import           Servant

type RenderAPI = "api" :> "render" :> "instance" :> Capture "DeploymentInstanceKey" Text :> AuthHeader :> Get '[PlainText] Text
