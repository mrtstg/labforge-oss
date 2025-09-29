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
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
module Config
  ( AppT(..)
  , Config(..)
  , defaultLogF
  , filterLogF
  , runClientApp
  , appTIO
  ) where

import           Api.Keycloak.Token
import           Control.Monad.Except        (MonadError)
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.ByteString.Char8       (unpack)
import           Data.Pool                   (Pool)
import           Data.Text                   (Text)
import           Database.Persist.Postgresql
import           Database.Redis
import           Models
import           Pool                        (AsyncPool)
import           Redis.Common
import           Servant
import           Servant.Client
import           Service.Environment

appTIO :: AppT a -> Config -> IO (Either ServerError a)
appTIO m cfg = (runHandler . flip runReaderT cfg . runApp) m

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
  { configDBPool       :: !(Pool SqlBackend)
  , logFunction        :: !LogFunction
  , serviceCredentials :: !(Text, Text)
  , authToken          :: !(TokenVariable Text)
  , authFunctions      :: TokenVariableFunctions Text
  , clusterEnv         :: !ClientEnv
  --, rabbitConnection   :: !Connection
  , authEnv            :: !ClientEnv
  , tasksPool          :: AsyncPool QueryRequest AppT
  , deploySDNZone      :: !Text
  , redisConnection    :: !Connection
  }

instance ServiceEnvironment Config where
  getEnvFor AuthService       = authEnv
  getEnvFor ClusterManager    = clusterEnv
  getEnvFor DeploymentService = error "DeploymentService env is not specified"

instance RedisConnection Config where
  getRedisConnection = asks redisConnection

instance HasTokenVariable Config Text where
  getTokenVariable = authToken
  getTokenFunctions = authFunctions

runClientApp :: ClientEnv -> ClientM a -> AppT (Either ClientError a)
runClientApp env m = liftIO $ runClientM m env

defaultLogF :: LogFunction
defaultLogF loc src level msg = (putStr . unpack . fromLogStr) (defaultLogStr loc src level msg)

filterLogF :: LogLevel -> LogFunction
filterLogF compareLevel loc src level msg = when (level >= compareLevel) $ defaultLogF loc src level msg
