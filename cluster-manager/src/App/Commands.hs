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
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
module App.Commands (runCommand) where

import           Api.Keycloak.Token
import           App
import           App.Types
import           Auth.Token
import           Cluster.Models.Node
import           Config
import           Control.Monad                       (when)
import           Control.Monad.Logger
import           Data.ByteString.Char8               (ByteString)
import           Data.Maybe
import           Data.Pool                           (Pool)
import           Data.Text                           (pack)
import qualified Data.Text                           as T
import           Database
import           Database.Persist.Postgresql
import           Network.Wai.Handler.Warp
import           Network.Wai.Logger
import qualified Proxmox.Client                      as P
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.Deploy
import           Proxmox.Deploy.Ssl
import           Proxmox.Retry
import           Proxmox.Schema
import           Redis.Environment
import           Servant
import           Servant.Client
import           Service.Config
import           System.Environment
import           System.Exit

createPool :: Bool -> ByteString -> IO (Pool SqlBackend)
createPool debug url = do
  (if debug then runStdoutLoggingT else flip runLoggingT (\_ _ _ _ -> pure ())) $ createPostgresqlPool url 10

runCommand :: AppOpts -> IO ()
runCommand AppOpts { debugOn = debug, appCommand = AddNode { .. } } = do
  let clusterData = ClusterNode { nodeStartVMID = Just nodeStartVMID'
    , nodeName=nodeName'
    , nodeMinDisplay=nodeMinDisplay'
    , nodeMaxDisplay=nodeMaxDisplay'
    , nodeIgnoreSSL=nodeIgnoreSSL'
    , nodeExcludedPorts=nodeExcludedPorts'
    , nodeDisplayNetwork=nodeDisplayNetwork'
    , nodeDisplayIP=nodeDisplayIP'
    , nodeApiUrl=nodeApiUrl'
    , nodeApiToken=nodeApiToken'
    , nodeAgentUrl=nodeAgentUrl'
    , nodeAgentToken=nodeAgentToken'
    }
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo
  url <- runLoggingT requirePostgresString logFunction
  pool <- App.Commands.createPool debug url
  nodeData <- flip runSqlPool pool $ selectFirst [ DeployNodeName ==. nodeName' ] []
  case nodeData of
    (Just _) -> do
      putStrLn "Node exists!"
      exitWith (ExitFailure 1)
    Nothing -> do
      _ <- flip runSqlPool pool $ insert (DeployNode nodeName' clusterData)
      putStrLn "Node created!"
runCommand AppOpts { debugOn = debug, appCommand = CheckNode nodeName } = do
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo
  url <- runLoggingT requirePostgresString logFunction
  pool <- App.Commands.createPool debug url
  nodeData <- flip runSqlPool pool $ selectFirst [ DeployNodeName ==. nodeName ] []
  case nodeData of
    Nothing -> do
      putStrLn "Node not found"
      exitWith (ExitFailure 1)
    (Just (Entity _ DeployNode { deployNodeData = (ClusterNode { .. }),.. })) -> do
      proxmoxUrl <- (parseBaseUrl . T.unpack) nodeApiUrl
      mgr <- createProxmoxManager (DeployConfig { deployParameters = DeployParams {deployUrl=nodeApiUrl, deployToken=Just nodeApiToken, deployStartVMID=0, deployIgnoreSSL=nodeIgnoreSSL, deployNodeName=nodeName}, deployTemplates = [], deployVMs = [], deployAgent = Nothing, deployNetworks = [] })
      let state = ProxmoxState proxmoxUrl mgr
      r <- flip runLoggingT logFunction $ defaultRetryClient' state P.getVersion
      case r of
        (Left e) -> do
          putStrLn $ "Failure response: " <> show e
          exitWith (ExitFailure 1)
        (Right _) -> putStrLn "Successful response!"
runCommand AppOpts { debugOn = debug, appCommand = RemoveNode nodeName } = do
  let logFunction = if debug then defaultLogF else filterLogF LevelInfo
  url <- runLoggingT requirePostgresString logFunction
  pool <- App.Commands.createPool debug url
  flip runSqlPool pool $ deleteWhere [ DeployNodeName ==. nodeName ]
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

  _ <- do
    e <- getEnvironment
    flip runLoggingT logFunction $ $(logDebug) $ "Current environment: " <> (pack . show) e

  creds <- runLoggingT requireKeycloakClient logFunction
  tokenV <- createTokenVar
  (authUrl, authManager) <- runLoggingT (requireServiceEnv "AUTH") logFunction

  let authEnv = mkClientEnv authManager authUrl
  let config = Config { serviceCredentials=creds
    , logFunction=logFunction
    , configDBPool=pool
    , authToken=tokenV
    , authEnv=authEnv
    , authFunctions=genericTokenFunctions logFunction creds authEnv
    }
  let app' = app config
  _ <- flip runLoggingT logFunction $ $(logInfo) "Starting server!"
  withStdoutLogger $ \aplogger -> do
    let settings = setPort port $ setLogger aplogger defaultSettings
    runSettings settings app'
