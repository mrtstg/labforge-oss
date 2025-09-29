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
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
module App.Commands (runCommand) where

import           Api.Keycloak.Token
import           App.Types
import           Auth.Token
import           Config
import           Control.Concurrent
import           Control.Monad              (forever, when)
import           Control.Monad.Logger
import qualified Data.ByteString.Lazy.Char8 as LBS
import           Data.Text                  (pack)
import           Network.AMQP
import           Pool
import           Servant.Client
import           Service.Config
import           System.Environment

f :: String -> AppT ()
f msg = do
  $(logInfo) $ pack msg
  pure ()

runCommand :: AppOpts -> IO ()
runCommand AppOpts { debugOn=debug } = do
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo

  _ <- do
    e <- getEnvironment
    flip runLoggingT logFunction $ $(logDebug) $ "Current environment: " <> (pack . show) e

  creds <- runLoggingT requireKeycloakClient logFunction
  tokenV <- createTokenVar
  (authUrl, authManager) <- runLoggingT (requireServiceEnv "AUTH") logFunction
  amqpConn <- runLoggingT (requireRabbitMQCreds openConnection') logFunction
  channel <- openChannel amqpConn
  (queue, _, _) <- declareQueue channel newQueue { queueName = "testQueue" }

  let config = Config { serviceCredentials=creds
    , logFunction=logFunction
    , authToken=tokenV
    , authFunctions=genericTokenFunctions logFunction creds (mkClientEnv authManager authUrl)
    }
  _ <- flip runLoggingT logFunction $ $(logInfo) "Starting server!"
  pool <- createPool f (flip appTIO config) 4
  forever $ do
    res <- getMsg channel NoAck queue
    case res of
      Nothing -> threadDelay 100000 >> pure ()
      (Just (msg, env)) -> do
        putTask pool (LBS.unpack . msgBody $ msg)
  return ()
