module Kroki.Client
  ( renderInstanceDiagram
  ) where

import           Data.Proxy
import           Kroki.Schema
import           Servant.Client

api :: Proxy RenderAPI
api = Proxy

renderInstanceDiagram = client api
