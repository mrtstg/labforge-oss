{-# LANGUAGE NumericUnderscores #-}
module Api.Retry
  ( retryClient
  , defaultRetryClient
  , defaultRetryClient'
  ) where

import System.Log.Logger
import Control.Concurrent
import Servant.Client
import Api.Proxmox

type RetryAmount = Int
type RetryTimeout = Int

loggerName = "ProxmoxCompose.Retry"

defaultRetryClient' :: ProxmoxState -> ClientM a -> IO (Either ClientError a)
defaultRetryClient' (ProxmoxState url manager') = defaultRetryClient (mkClientEnv manager' url)

defaultRetryClient :: ClientEnv -> ClientM a -> IO (Either ClientError a)
defaultRetryClient env res = retryClient env res 5 1_500_000

retryClient :: ClientEnv -> ClientM a -> RetryAmount -> RetryTimeout -> IO (Either ClientError a)
retryClient env res 0 _ = runClientM res env
retryClient env res retryA retryT = do
  res' <- runClientM res env
  case res' of
    (Left e) -> do
      warningM loggerName "Got API request error, retrying..."
      debugM loggerName $ "Retrying client error: " <> show e
      threadDelay retryT
      retryClient env res (retryA - 1) retryT
    (Right v) -> (pure . Right) v 
