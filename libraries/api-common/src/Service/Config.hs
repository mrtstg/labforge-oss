{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
module Service.Config
  ( requireEnv
  , requireKeycloakClient
  , requireEnvUrl
  , requireServiceEnv
  , lookupEnvDefault
  , requirePostgresString
  , requireRabbitMQCreds
  ) where

import           Control.Monad.Catch
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import qualified Data.ByteString.Char8       as BS
import           Data.Functor                ((<&>))
import           Data.Maybe
import           Data.Text                   (Text, pack, unpack)
import           Network.HTTP.Client.Conduit
import           Network.Socket
import           Servant.Client
import           Service.Ssl
import           System.Environment
import           System.Exit
import           Text.Read

-- passing connection create string and function substitutes them
requireRabbitMQCreds :: (String -> PortNumber -> Text -> Text -> Text -> IO a) -> LoggingT IO a
requireRabbitMQCreds f' = let
  f :: (MonadIO m) => Text -> LoggingT m a
  f msg = $(logError) msg >> (liftIO . exitWith) (ExitFailure 1)
  in do
    rmqHost <- requireEnv "RABBITMQ_HOST" (f "RABBITMQ_HOST is not set")
    rmqPort <- lookupEnvDefault "RABBITMQ_PORT" 5672
    rmqUser <- requireEnvText "RABBITMQ_USER" (f "RABBITMQ_USER is not set")
    rmqPass <- requireEnvText "RABBITMQ_PASS" (f "RABBITMQ_PASS is not set")
    rmqVhost <- liftIO $ lookupEnv "RABBITMQ_VHOST" <&> (pack . fromMaybe "/")
    liftIO $ f' rmqHost rmqPort rmqVhost rmqUser rmqPass

requirePostgresString :: (MonadIO m) => LoggingT m BS.ByteString
requirePostgresString = let
  f :: (MonadIO m) => Text -> LoggingT m a
  f msg = $(logError) msg >> (liftIO . exitWith) (ExitFailure 1)
  in do
  dbUser' <- requireEnv "POSTGRES_USER" (f "POSTGRES_USER is not set")
  dbPass' <- requireEnv "POSTGRES_PASSWORD" (f "POSTGRES_PASSWORD is not set")
  dbName' <- requireEnv "POSTGRES_DB" (f "POSTGRES_DB is not set")
  dbHost' <- requireEnv "POSTGRES_HOST" (f "POSTGRES_HOST is not set")
  dbPort' <- lookupEnvDefault "POSTGRES_PORT" 5432
  (return . BS.pack) $ "user=" <>
      dbUser' <>
      " password=" <>
      dbPass' <>
      " host=" <>
      dbHost' <>
      " port=" <>
      show dbPort' <>
      " dbname=" <>
      dbName'

lookupEnvDefault :: (Read a, MonadIO m) => String -> a -> LoggingT m a
lookupEnvDefault envKey def = do
  $(logDebug) $ "Looking for variable " <> pack envKey
  v <- (liftIO . lookupEnv) envKey
  case v of
    Nothing -> do
      $(logDebug) $ "Variable " <> pack envKey <> " not found. Returning default..."
      pure def
    (Just v') -> case readMaybe v' of
      Nothing    -> do
        $(logDebug) $ "Can't parse variable" <> pack envKey <> ". Returning default..."
        pure def
      (Just v'') -> pure v''

requireServiceEnv :: (MonadIO m, MonadCatch m) => String -> LoggingT m (BaseUrl, Manager)
requireServiceEnv prefix = let
  urlKey = prefix <> "_URL"
  sslKey = prefix <> "_IGNORE_SSL"

  in do
    ssl' <- liftIO $ lookupEnv sslKey <&> fromMaybe "0"
    url' <- requireEnvUrl urlKey
    mgr <- liftIO $ createSSLManager (ssl' == "1")
    return (url', mgr)

requireEnvText :: (MonadIO m) => String -> LoggingT m String -> LoggingT m Text
requireEnvText e f = requireEnv e f <&> pack

requireEnv :: (MonadIO m) => String -> LoggingT m String -> LoggingT m String
requireEnv envKey onFail = do
  $(logDebug) $ "Looking for variable " <> pack envKey
  v <- (liftIO . lookupEnv) envKey
  case v of
    Nothing -> do
      $(logDebug) $ "Variable " <> pack envKey <> " is not found."
      onFail
    (Just v') -> pure v'

requireEnvRead :: (Read a, MonadIO m) => String -> (Maybe String -> LoggingT m a) -> LoggingT m a
requireEnvRead envKey onFail = do
  $(logDebug) $ "Looking for variable " <> pack envKey
  v <- (liftIO . lookupEnv) envKey
  case v of
    Nothing -> do
      $(logDebug) $ "Variable " <> pack envKey <> " is not found."
      onFail Nothing
    (Just v') -> case readMaybe v' of
      Nothing    -> do
        $(logDebug) $ "Can't parse variable " <> pack envKey
        onFail (Just v')
      (Just v'') -> pure v''

requireKeycloakClient :: (MonadIO m) => LoggingT m (Text, Text)
requireKeycloakClient = let
  f :: (MonadIO m) => LoggingT m a
  f = do
    $(logError) "KEYCLOAK_CLIENT_SECRET or KEYCLOAK_CLIENT_ID is not provided"
    liftIO $ exitWith (ExitFailure 1)
  in do
    id' <- requireEnvText "KEYCLOAK_CLIENT_ID" f
    secret' <- requireEnvText "KEYCLOAK_CLIENT_SECRET" f
    return (id', secret')

requireEnvUrl :: (MonadIO m, MonadCatch m) => String -> LoggingT m BaseUrl
requireEnvUrl envKey = do
  rawUrl <- requireEnv envKey ($(logError) ("Following URL is not provided: " <> pack envKey) >> (liftIO . exitWith) (ExitFailure 1))
  parseRes <- try $ parseBaseUrl rawUrl
  case parseRes of
    (Left (e :: SomeException)) -> do
      $(logError) ("Failed to parse " <> pack envKey <> " into URL: " <> (pack . show) e)
      (liftIO . exitWith) (ExitFailure 1)
    (Right url) -> pure url
