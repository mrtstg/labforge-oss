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
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
module App.Commands (runCommand) where

import           Api
import           Api.Keycloak.Models
import           Api.Keycloak.Token
import           Api.Retry
import           App.Types
import           Auth.Token
import           Config
import           Control.Concurrent
import           Control.Monad                   (forever, when)
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8      as LBS
import           Data.List                       (nub)
import           Data.Maybe
import           Data.Text                       (pack)
import           Deployment.Client
import           Deployment.Models.Deployment
import           Jobservice.Models
import           Network.AMQP
import           Pool
import           Proxmox.Deploy.Models.Config.VM
import           Redis.Common
import           Redis.Environment
import           Servant.Client
import           Service.Config
import           Service.Environment
import           System.Environment
import           System.Exit

getAllTemplates :: AppT (Maybe [DeploymentTemplate])
getAllTemplates = let
  helper :: [DeploymentTemplate] -> Int -> AppT (Maybe [DeploymentTemplate])
  helper acc page = do
    env <- asks $ getEnvFor DeploymentService
    res <- withTokenVariable $ \token -> do
      defaultRetryClientC env (getPagedDeploymentTemplates (Just page) (BearerWrapper token))
    case res of
      (Left _) -> $(logError) "Token issue error" >> pure Nothing
      (Right r) -> do
        case r of
          (Left e) -> do
            $(logError) $ "Client error: " <> (pack . show) e
            pure Nothing
          (Right (PagedResponse { .. })) -> do
            case responseObjects of
              [] -> (pure . Just) acc
              elems -> do
                helper (elems ++ acc) (page + 1)
  in helper [] 1

f :: (Envelope, Message) -> AppT ()
f (env, msg) = do
  case eitherDecode (msgBody msg) of
    (Left e) -> do
      liftIO $ ackEnv env
      $(logError) $ "Decode error: " <> pack e
    (Right (JobserviceUpdateUsedImages {})) -> do
      $(logInfo) "Updating used images"
      deleteValue' jobserviceUsedImagesKey
      $(logInfo) "Getting templates"
      tmpls <- getAllTemplates
      case tmpls of
        Nothing -> $(logError) "Failed to get templates"
        (Just d) -> do
          let usedTemplates = nub $ foldMap (map configVMParentTemplate . filter isTemplateVM . templateVMs) d
          cacheValue' jobserviceUsedImagesKey (LBS.unpack . encode $ usedTemplates) (Just 600)
          $(logInfo) "Value updated!"
      pure ()

runCommand :: AppOpts -> IO ()
runCommand AppOpts { debugOn=debug } = do
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo

  _ <- do
    e <- getEnvironment
    flip runLoggingT logFunction $ $(logDebug) $ "Current environment: " <> (pack . show) e

  redis <- redisConnectionFromEnv
  when (isNothing redis) $ do
    flip runLoggingT logFunction $ $(logError) "Failed to build Redis connection"
    exitWith (ExitFailure 1)
  creds <- runLoggingT requireKeycloakClient logFunction
  tokenV <- createTokenVar
  (authUrl, authManager) <- runLoggingT (requireServiceEnv "AUTH") logFunction
  (depUrl, depManager) <- runLoggingT (requireServiceEnv "DEPLOYMENT") logFunction
  amqpConn <- runLoggingT (requireRabbitMQCreds openConnection') logFunction
  channel <- openChannel amqpConn
  (queue, _, _) <- declareQueue channel newQueue { queueName = "testQueue" }

  let config = Config { serviceCredentials=creds
    , logFunction=logFunction
    , authToken=tokenV
    , authEnv=mkClientEnv authManager authUrl
    , deploymentEnv=mkClientEnv depManager depUrl
    , authFunctions=genericTokenFunctions logFunction creds (mkClientEnv authManager authUrl)
    , redisConnection=fromJust redis
    }
  _ <- flip runLoggingT logFunction $ $(logInfo) "Starting server!"
  pool <- createPool f (`appTIO` config) 4
  _ <- forever $ do
    res <- getMsg channel Ack queue
    case res of
      Nothing -> threadDelay 100000
      (Just (msg, env)) -> do
        putTask pool (env, msg)
  return ()
