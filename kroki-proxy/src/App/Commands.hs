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

import           Api.Keycloak.Token
import           App
import           App.Types
import           Auth.Token
import           Config
import           Control.Monad               (when)
import           Control.Monad.Logger
import           Data.ByteString.Char8       (ByteString)
import           Data.Pool                   (Pool)
import           Data.Text                   (pack)
import           Database.Persist.Postgresql
import           Database.Persist.Sqlite
import           Network.Wai.Handler.Warp
import           Network.Wai.Logger
import           Redis.Common
import           Redis.Environment
import           Servant.Client
import           Service.Config
import           System.Environment
import           System.Exit

runCommand :: AppOpts -> IO ()
runCommand AppOpts { debugOn=debug, appCommand=MakeMigrations } = pure ()
runCommand AppOpts { debugOn=debug, appCommand=RunServerOn port runMigrate } = do
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo

  _ <- do
    e <- getEnvironment
    flip runLoggingT logFunction $ $(logDebug) $ "Current environment: " <> (pack . show) e

  creds <- runLoggingT requireKeycloakClient logFunction
  tokenV <- createTokenVar
  (authUrl, authManager) <- runLoggingT (requireServiceEnv "AUTH") logFunction
  (krokiUrl, krokiManager) <- runLoggingT (requireServiceEnv "KROKI_SERVER") logFunction
  (deployUrl, deployManager) <- runLoggingT (requireServiceEnv "DEPLOYMENT") logFunction
  let authEnv = mkClientEnv authManager authUrl
  redisC <- redisConnectionFromEnv
  case redisC of
    Nothing -> (flip runLoggingT logFunction $ $(logError) "Redis connection is not provided") >> exitWith (ExitFailure 1)
    (Just redis) -> do
      let config = Config { redisConnection = redis
        , serviceCredentials=creds
        , logFunction=logFunction
        , authToken=tokenV
        , authEnv=authEnv
        , authFunctions=genericTokenFunctions logFunction creds authEnv
        , krokiEnv=mkClientEnv krokiManager krokiUrl
        , deploymentEnv=mkClientEnv deployManager deployUrl
        }
      let app' = app config
      _ <- flip runLoggingT logFunction $ $(logInfo) "Starting server!"
      withStdoutLogger $ \aplogger -> do
        let settings = setPort port $ setLogger aplogger defaultSettings
        runSettings settings app'
