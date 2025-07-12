{-# LANGUAGE NumericUnderscores #-}
module Api.Retry
  ( retryClient
  , defaultRetryClient
  , defaultRetryClient'
  , waitForClient
  , retryClient'
  ) where

import           Api.Proxmox
import           Control.Concurrent
import           Servant.Client
import           System.Log.Logger

type RetryAmount = Int
type RetryTimeout = Int

loggerName = "ProxmoxCompose.Retry"

defaultRetryClient' :: ProxmoxState -> ClientM a -> IO (Either ClientError a)
defaultRetryClient' (ProxmoxState url manager') = defaultRetryClient (mkClientEnv manager' url)

defaultRetryClient :: ClientEnv -> ClientM a -> IO (Either ClientError a)
defaultRetryClient env = retryClient env 5 1_500_000

retryClient' :: ProxmoxState -> RetryAmount -> RetryTimeout -> ClientM a -> IO (Either ClientError a)
retryClient' (ProxmoxState url manager') = retryClient (mkClientEnv manager' url)

retryClient :: ClientEnv -> RetryAmount -> RetryTimeout -> ClientM a -> IO (Either ClientError a)
retryClient env 0 _ res = runClientM res env
retryClient env retryA retryT res = do
  res' <- runClientM res env
  case res' of
    (Left e) -> do
      warningM loggerName "Got API request error, retrying..."
      debugM loggerName $ "Retrying client error: " <> show e
      threadDelay retryT
      retryClient env (retryA - 1) retryT res
    (Right v) -> (pure . Right) v

type FailureMessage = String
type MaxRetryT = Int

waitForClient :: MaxRetryT -> FailureMessage -> RetryAmount -> RetryTimeout -> IO (Either ClientError a) -> (a -> Bool) -> IO (Either ClientError Bool)
waitForClient maxRetryT failMessage retryA retryT' v f = do
  let retryT = min maxRetryT retryT'
  res' <- v
  case res' of
    (Left e) -> if retryA <= 1 then (pure . Left) e else do
      warningM loggerName "Error during API request. Retry..."
      threadDelay retryT
      waitForClient maxRetryT failMessage (retryA - 1) retryT v f
    (Right res) -> do
      let checkRes = f res
      if checkRes || retryA <= 1 then (pure . Right) checkRes else do
        infoM loggerName failMessage
        threadDelay retryT
        waitForClient maxRetryT failMessage (retryA - 1) (retryT * 2) v f
