{- Copyright (C) 2025 Ilya Zamaratskikh

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, see <http://www.gnu.org/licenses>. -}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE TemplateHaskell    #-}
module App.Commands (runCommand) where

import           Api.Keycloak.Token
import           App
import           App.Types
import           Auth.Token
import           Config
import           Control.Concurrent
import           Control.Concurrent.Async
import           Control.Exception
import           Control.Monad               (void, when)
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import           Data.ByteString.Char8       (ByteString)
import qualified Data.ByteString.Lazy.Char8  as BLS
import           Data.Maybe
import           Data.Pool                   (Pool)
import           Data.Text                   (pack)
import           Database
import           Database.Persist.Postgresql
import           Database.Persist.Sqlite
import           Jobservice.Models
import           Network.AMQP
import           Network.Wai.Handler.Warp
import           Network.Wai.Logger
import           Redis.Common
import           Redis.Environment
import           Servant.Client
import           Service.Config
import           System.Environment
import           System.Exit

createPool :: Bool -> ByteString -> IO (Pool SqlBackend)
createPool debug url = do
  (if debug then runStdoutLoggingT else flip runLoggingT (\_ _ _ _ -> pure ())) $ createPostgresqlPool url 10

f :: Config -> IO ()
f cfg = forever $ do
  catch (void $ appTIO inner cfg) err
  threadDelay 60_000_000
  where
  err :: SomeException -> IO ()
  err _ = pure ()

  inner :: AppT ()
  inner = do
    $(logInfo) "Checking images key"
    v <- getValue' jobserviceUsedImagesKey
    case v of
      (Just _) -> $(logInfo) "Images key found"
      Nothing -> do
        $(logInfo) "Creating images request"
        r <- asks rabbitConnection
        chan <- liftIO $ openChannel r
        let msg = newMsg { msgBody = encode (JobserviceTask Nothing JobserviceUpdateUsedImages {}), msgDeliveryMode = Just NonPersistent }
        _ <- liftIO $ publishMsg chan "jobserviceExchange" "" msg
        liftIO $ closeChannel chan
        liftIO $ threadDelay (5 * 60_000_000)

runCommand :: AppOpts -> IO ()
runCommand AppOpts { debugOn=debug, appCommand=MakeMigrations } = do
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo
  url <- runLoggingT requirePostgresString logFunction
  pool <- createPool debug url
  runSqlPool doMigration pool
runCommand AppOpts { debugOn=debug, appCommand=RunServerOn port runMigrate } = do
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo
  url <- runLoggingT requirePostgresString logFunction
  pool <- createPool debug url
  when runMigrate $ runSqlPool doMigration pool

  redisC <- redisConnectionFromEnv
  when (isNothing redisC) $ do
    flip runLoggingT logFunction $ $(logError) "Failed to init redis connection"
    exitWith (ExitFailure 1)

  _ <- do
    e <- getEnvironment
    flip runLoggingT logFunction $ $(logDebug) $ "Current environment: " <> (pack . show) e

  creds <- runLoggingT requireKeycloakClient logFunction
  tokenV <- createTokenVar
  (authUrl, authManager) <- runLoggingT (requireServiceEnv "AUTH") logFunction

  amqpConn <- runLoggingT (requireRabbitMQCreds openConnection') logFunction

  let config = Config { serviceCredentials=creds
    , logFunction=logFunction
    , configDBPool=pool
    , authToken=tokenV
    , authEnv=mkClientEnv authManager authUrl
    , authFunctions=genericTokenFunctions logFunction creds (mkClientEnv authManager authUrl)
    , redisConnection=fromJust redisC
    , rabbitConnection = amqpConn
    }
  let app' = app config

  _ <- async $ f config

  _ <- flip runLoggingT logFunction $ $(logInfo) "Starting server!"
  withStdoutLogger $ \aplogger -> do
    let settings = setPort port $ setLogger aplogger defaultSettings
    runSettings settings app'
