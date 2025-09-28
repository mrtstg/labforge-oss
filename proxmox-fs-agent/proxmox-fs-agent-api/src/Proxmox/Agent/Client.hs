module Proxmox.Agent.Client
  ( setVNCPort
  , VNCRequest(..)
  , AgentToken(..)
  ) where

import           Control.Monad.Except
import           Control.Monad.Reader
import           Data.Proxy
import           Network.HTTP.Types
import           Proxmox.Agent.Schema
import           Servant.Client

api :: Proxy AgentAPI
api = Proxy

setVNCPort' = client api

setVNCPort vmid token req = noContentStatusWrapper $ setVNCPort' vmid token req

noContentStatusWrapper :: ClientM a -> ClientM ()
noContentStatusWrapper req = do
  state <- ask
  res <- liftIO $ runClientM req state
  case res of
    (Right _) -> pure ()
    (Left exception@(FailureResponse _ (Response { responseStatusCode = status, responseBody = _ }))) -> do
      let stCode = statusCode status
      if stCode >= 200 && stCode < 300 then pure () else throwError exception
    (Left otherException) -> throwError otherException
