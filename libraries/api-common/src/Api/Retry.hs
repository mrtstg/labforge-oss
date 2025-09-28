{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE TemplateHaskell    #-}
module Api.Retry
  ( retryClient
  , defaultRetryClient
  , waitForClient
  , retryClientC
  , defaultRetryClientC
  ) where

import           Control.Concurrent
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import qualified Data.ByteString.Char8     as BS
import           Data.Text
import           Network.HTTP.Types.Status
import           Servant.Client

type RetryAmount = Int
type RetryTimeout = Int

defaultRetryClient :: (MonadLoggerIO m) => ClientEnv -> ClientM a -> m (Either ClientError a)
defaultRetryClient env = retryClient env 5 1_500_000

defaultRetryClientC :: (MonadLoggerIO m) => ClientEnv -> ClientM a -> m (Either ClientError a)
defaultRetryClientC env = retryClientC env 5 1_500_000

retryClientC :: (MonadLogger m, MonadIO m) => ClientEnv -> RetryAmount -> RetryTimeout -> ClientM a -> m (Either ClientError a)
retryClientC env 0 _ res = liftIO (runClientM res env)
retryClientC env retryA retryT res = do
  res' <- liftIO $ runClientM res env
  case res' of
    (Left e) -> do
      case e of
        (FailureResponse _ _) -> (pure . Left) e
        _anyOther -> do
          $(logDebug) $ "Retrying client error: " <> (pack . show) e
          (liftIO . threadDelay) retryT
          retryClientC env (retryA - 1) retryT res
    (Right v) -> (pure . Right) v

retryClient :: (MonadLogger m, MonadIO m) => ClientEnv -> RetryAmount -> RetryTimeout -> ClientM a -> m (Either ClientError a)
retryClient env 0 _ res = liftIO (runClientM res env)
retryClient env retryA retryT res = do
  res' <- liftIO $ runClientM res env
  case res' of
    (Left e) -> do
      case e of
        (FailureResponse _ (Response { responseStatusCode = status })) -> do
          case (BS.unpack . statusMessage) status of
            "" -> $(logWarn) $ "Got API request error [" <> (pack . show . statusCode) status <> "]"
            statusMessage' -> $(logWarn) $ "Got API request error [" <> (pack . show . statusCode) status <> "]: " <> pack statusMessage'
        (ConnectionError err) -> $(logWarn) $ "Got API connection error, retrying: " <> (pack . show) err
        _ -> $(logWarn) "Got API request decode error, retrying..."
      $(logDebug) $ "Retrying client error: " <> (pack . show) e
      (liftIO . threadDelay) retryT
      retryClient env (retryA - 1) retryT res
    (Right v) -> (pure . Right) v

type FailureMessage = Text
type MaxRetryT = Int

waitForClient :: (MonadIO m, MonadLogger m) => MaxRetryT -> FailureMessage -> RetryAmount -> RetryTimeout -> IO (Either ClientError a) -> (a -> Bool) -> m (Either ClientError Bool)
waitForClient maxRetryT failMessage retryA retryT' v f = do
  let retryT = min maxRetryT retryT'
  res' <- liftIO v
  case res' of
    (Left e) -> if retryA <= 1 then (pure . Left) e else do
      $(logWarn) "Error during API request. Retry..."
      (liftIO . threadDelay) retryT
      waitForClient maxRetryT failMessage (retryA - 1) retryT v f
    (Right res) -> do
      let checkRes = f res
      if checkRes || retryA <= 1 then (pure . Right) checkRes else do
        $(logInfo) failMessage
        (liftIO . threadDelay) retryT
        waitForClient maxRetryT failMessage (retryA - 1) (retryT * 2) v f
