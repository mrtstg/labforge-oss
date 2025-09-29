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
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}
module App.Commands (runCommand) where

import           Api.Handler
import           Api.Keycloak.Token
import           App
import           App.Types
import           Auth.Token
import           Config
import           Control.Monad               (when)
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Data.ByteString.Char8       (ByteString)
import           Data.Maybe
import           Data.Pool                   (Pool)
import           Data.Text                   (pack)
import           Database
import           Database.Persist.Postgresql
import           Database.Persist.Sqlite
import           Network.AMQP
import           Network.Wai.Handler.Warp
import           Network.Wai.Logger
import           Pool
import           Redis.Environment
import           Servant.Client
import           Service.Config
import           System.Environment
import           System.Exit

createPool :: Bool -> ByteString -> IO (Pool SqlBackend)
createPool debug url = do
  (if debug then runStdoutLoggingT else flip runLoggingT (\_ _ _ _ -> pure ())) $ createPostgresqlPool url 10

runCommand :: AppOpts -> IO ()
runCommand AppOpts { debugOn=debug, appCommand=MakeMigrations } = do
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo
  url <- runLoggingT requirePostgresString logFunction
  pool <- App.Commands.createPool debug url
  runSqlPool doMigration pool
runCommand AppOpts { debugOn=debug, appCommand=RunServerOn port runMigrate } = do
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo
  url <- runLoggingT requirePostgresString logFunction
  pool <- App.Commands.createPool debug url
  when runMigrate $ runSqlPool doMigration pool

  _ <- do
    e <- getEnvironment
    flip runLoggingT logFunction $ $(logDebug) $ "Current environment: " <> (pack . show) e

  creds <- runLoggingT requireKeycloakClient logFunction
  tokenV <- createTokenVar
  (authUrl, authManager) <- runLoggingT (requireServiceEnv "AUTH") logFunction
  (clusterUrl, clusterManager) <- runLoggingT (requireServiceEnv "CLUSTER") logFunction
  --rmqConn <- runLoggingT (requireRabbitMQCreds openConnection') logFunction
  deployZone <- runLoggingT
    (requireEnv "DEPLOY_SDN_ZONE" ($(logError) "DEPLOY_SDN_ZONE is not set" >> (liftIO . exitWith) (ExitFailure 1))) logFunction

  redisConn <- redisConnectionFromEnv
  when (isNothing redisConn) $ do
    runLoggingT ($(logError) "Redis connection is not set") logFunction
    exitWith (ExitFailure 1)

  -- TODO: solve this shi
  let poolConfig = Config { serviceCredentials=creds
    , logFunction=logFunction
    , configDBPool=pool
    , authToken=tokenV
    , authFunctions=genericTokenFunctions logFunction creds (mkClientEnv authManager authUrl)
    , clusterEnv = mkClientEnv clusterManager clusterUrl
    --, rabbitConnection = rmqConn
    , authEnv = mkClientEnv authManager authUrl
    , tasksPool = error "Pool is not created"
    , deploySDNZone = pack deployZone
    , redisConnection = fromJust redisConn
    }

  tasksPool <- Pool.createPool handleTask (\m -> appTIO m poolConfig >> pure ()) 1

  let config = Config { serviceCredentials=creds
    , logFunction=logFunction
    , configDBPool=pool
    , authToken=tokenV
    , authFunctions=genericTokenFunctions logFunction creds (mkClientEnv authManager authUrl)
    , clusterEnv = mkClientEnv clusterManager clusterUrl
    --, rabbitConnection = rmqConn
    , authEnv = mkClientEnv authManager authUrl
    , tasksPool = tasksPool
    , deploySDNZone = pack deployZone
    , redisConnection = fromJust redisConn
    }
  let app' = app config
  _ <- flip runLoggingT logFunction $ $(logInfo) "Starting server!"
  withStdoutLogger $ \aplogger -> do
    let settings = setPort port $ setLogger aplogger defaultSettings
    runSettings settings app'
