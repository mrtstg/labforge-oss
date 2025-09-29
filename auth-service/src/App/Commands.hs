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
module App.Commands (runCommand) where

import           Api.Keycloak.Token
import           App
import           App.Types
import           Config
import           Control.Monad
import           Control.Monad.Logger
import           Control.Monad.Logger        (LogLevel (..))
import           Data.Functor                ((<&>))
import           Data.Maybe
import qualified Data.Text                   as T
import           Network.HTTP.Client.Conduit (defaultManagerSettings)
import           Network.HTTP.Conduit
import           Network.Wai.Handler.Warp
import           Network.Wai.Logger
import           Redis.Environment           (redisConnectionFromEnv)
import           Servant.Client              (mkClientEnv, parseBaseUrl)
import           Service.Config
import           System.Environment
import           System.Exit
import           Text.Read

runCommand :: AppOpts -> IO ()
runCommand AppOpts { debugOn=debug, appCommand=MakeMigrations } = pure ()
runCommand AppOpts { debugOn=debug, appCommand=RunServerOn port _ } = do
  realm <- lookupEnv "KEYCLOAK_REALM" <&> T.pack . fromMaybe "ln2"
  authClient <- lookupEnv "AUTH_KEYCLOAK_CLIENT" <&> T.pack . fromMaybe "ln2"
  callbackUrl <- lookupEnv "AUTH_CALLBACK_URL" <&> T.pack . fromMaybe ""
  cookieAge <- lookupEnv "AUTH_COOKIE_AGE" <&> read . fromMaybe "86400"
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo
  (keycloakUrl, keycloakManager) <- runLoggingT (requireServiceEnv "KEYCLOAK") logFunction
  redisConn <- redisConnectionFromEnv
  when (isNothing redisConn) $ do
    putStrLn "Failed to init redis connection"
    exitWith (ExitFailure 1)
  keycloakID <- lookupEnv "KEYCLOAK_CLIENT_ID" <&> T.pack . fromMaybe ""
  keycloakSecret <- lookupEnv "KEYCLOAK_CLIENT_SECRET" <&> T.pack . fromMaybe ""
  keycloakAuthSecret <- lookupEnv "AUTH_KEYCLOAK_SECRET" <&> T.pack . fromMaybe ""
  when (T.null keycloakID || T.null keycloakSecret || T.null callbackUrl || T.null keycloakAuthSecret) $ do
    putStrLn "Keycloak client credentials or endpoints is not entered"
    exitWith (ExitFailure 1)
  token <- createTokenVar
  let keycloakEnv = mkClientEnv keycloakManager keycloakUrl
  let config = Config { redisConnection=fromMaybe undefined redisConn
    , logFunction=logFunction
    , keycloakRealm=realm
    , keycloakUrl=keycloakUrl
    , keycloakEnv=keycloakEnv
    , keycloakClientID = keycloakID
    , keycloakClientSecret = keycloakSecret
    , authToken = token
    , authFunctions = defaultTokenVariableFunctions logFunction keycloakEnv realm keycloakID keycloakSecret
    , authCallbackURL = callbackUrl
    , authClient=authClient
    , authSecret=keycloakAuthSecret
    , authCookieAge=cookieAge
    }
  let app' = app config
  withStdoutLogger $ \aplogger -> do
    let settings = setPort port $ setLogger aplogger defaultSettings
    runSettings settings app'
