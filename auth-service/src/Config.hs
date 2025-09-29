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
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
module Config
  ( AppT(..)
  , Config(..)
  , defaultLogF
  , filterLogF
  , runClientApp
  , defaultTokenVariableFunctions
  ) where

import           Api.Keycloak.Client
import           Api.Keycloak.Models.Introspect
import           Api.Keycloak.Models.Token      (GrantRequest (ClientCredentialsRequest),
                                                 GrantResponse (..))
import qualified Api.Keycloak.Models.Token      as Token
import           Api.Keycloak.Token
import           Control.Monad.Except           (MonadError)
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.ByteString.Char8          (unpack)
import           Data.Text                      (Text)
import qualified Data.Text                      as T
import           Database.Redis
import           Redis.Common
import           Servant
import           Servant.Client

type LogFunction = Loc -> LogSource -> LogLevel -> LogStr -> IO ()

newtype AppT a = AppT { runApp :: ReaderT Config Handler a }
  deriving (Functor, Applicative, Monad, MonadIO, MonadReader Config, MonadError ServerError)

instance MonadLogger AppT where
  monadLoggerLog loc src level msg = do
    f <- asks logFunction
    liftIO $ f loc src level (toLogStr msg)

instance MonadLoggerIO AppT where
  askLoggerIO = asks logFunction

data Config = Config
  { redisConnection      :: !Connection
  , logFunction          :: !LogFunction
  , keycloakUrl          :: !BaseUrl
  , keycloakEnv          :: !ClientEnv
  , keycloakRealm        :: !Text
  , keycloakClientID     :: !Text
  , keycloakClientSecret :: !Text
  , authToken            :: TokenVariable Text
  , authFunctions        :: TokenVariableFunctions Text
  , authCallbackURL      :: !Text
  , authClient           :: !Text
  , authSecret           :: !Text
  , authCookieAge        :: !Int
  }

instance RedisConnection Config where
  getRedisConnection = redisConnection

instance HasTokenVariable Config Text where
  getTokenVariable = authToken
  getTokenFunctions = authFunctions

defaultTokenVariableFunctions :: LogFunction -> ClientEnv -> Text -> Text -> Text -> TokenVariableFunctions Text
defaultTokenVariableFunctions logF env realm cid csecret = let

  log' :: LogLevel -> Text -> IO ()
  log' level = logF defaultLoc "TokenVariable" level . toLogStr

  validate :: Text -> IO Bool
  validate token = do
    -- TODO: retry
    res <- flip runClientM env $ validateToken realm (IntrospectRequest {reqToken=token, reqClientSecret=csecret, reqClientID=cid})
    case res of
      (Left e)              -> do
        log' LevelWarn "Failed to validate token!"
        log' LevelDebug $ "Failed to validate token: " <> (T.pack . show) e
        pure False
      (Right InactiveToken) -> do
        log' LevelInfo "Token is inactive!"
        pure False
      _                     -> do
        log' LevelDebug "Token is valid."
        pure True

  issue :: IO (Either String Text)
  issue = do
    log' LevelInfo "Issuing new token."
    res <- flip runClientM env $ grantToken realm (ClientCredentialsRequest {Token.reqClientID=cid, Token.reqClientSecret=csecret})
    case res of
      (Left e)                                        -> do
        log' LevelError "Failed to issue new token."
        log' LevelDebug $ "Failed to issue new token: " <> (T.pack . show) e
        (pure . Left . show) e
      (Right (GrantResponse { accessToken = token })) -> do
        log' LevelInfo "Issued new token"
        (pure . pure) token

  in TokenFunctions {tokenValidateF=validate, tokenIssueF=issue}

runClientApp :: ClientEnv -> ClientM a -> AppT (Either ClientError a)
runClientApp env m = liftIO $ runClientM m env

defaultLogF :: LogFunction
defaultLogF loc src level msg = (putStr . unpack . fromLogStr) (defaultLogStr loc src level msg)

filterLogF :: LogLevel -> LogFunction
filterLogF compareLevel loc src level msg = when (level >= compareLevel) $ defaultLogF loc src level msg
