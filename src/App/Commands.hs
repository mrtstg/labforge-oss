{-# LANGUAGE RecordWildCards #-}
module App.Commands 
  ( runCommand
  ) where

import qualified Data.Text as T
import Api.Proxmox
import Api.Proxmox.Models.Version
import Api.Proxmox.Models
import qualified Api.Proxmox.Client as C
import Servant.Client
import Utils
import App.Types
import Control.Exception
import System.Exit
import Data.List (intercalate)
import Data.Models.Config.Deploy
import Data.Models.Config
import Api.Ssl (createProxmoxManager)
import App.Commands.Down
import System.Log.Handler (LogHandler(setFormatter))
import System.Log.Handler.Simple
import System.Log.Formatter
import System.IO
import System.Log
import System.Log.Logger (infoM, updateGlobalLogger, setLevel, rootLoggerName, setHandlers, errorM)
import App.Commands.Up
import Api.Retry

loggerName = "ProxmoxCompose.Main"

setupFormatter :: LogHandler a => a -> a
setupFormatter x = do
  setFormatter x (simpleLogFormatter "$time $prio $loggername: $msg")

setupLogging :: AppOpts -> IO ()
setupLogging opts = do
  let level = if verboseFlag opts then DEBUG else INFO
  handler <- streamHandler stdout level >>= \x -> pure $ setupFormatter x
  updateGlobalLogger rootLoggerName $ setHandlers [handler]
  updateGlobalLogger rootLoggerName (setLevel level)
  infoM loggerName "Started logging!"

parseDeployConfig :: AppOpts -> IO DeployConfig
parseDeployConfig AppOpts { .. } = let
 configFiles' = case configFile of
  Nothing -> defaultConfigFiles
  (Just path) -> path:defaultConfigFiles
 in do
  (configPath', checkedPaths) <- findExistingFile configFiles'
  case configPath' of
    Nothing -> do
      errorM loggerName $ "No available config files found. Checked: " <> intercalate "," checkedPaths
      exitWith (ExitFailure 1)
    (Just configPath) -> do
      configParseResult <- decodeDeployConfig configPath
      case configParseResult of
        (Left parseError) -> do
          errorM loggerName $ displayException parseError
          exitWith (ExitFailure 1)
        (Right deployConfig') -> do
          let deployConfig = updateDeployConfigToken optsToken deployConfig'
          case (deployToken . deployParameters) deployConfig of
            Nothing -> do
              errorM loggerName "Access token is not provided in file or command. Exiting..."
              exitWith (ExitFailure 1)
            _tokenExists -> do
              return deployConfig

runCommand :: AppOpts -> IO ()
runCommand opts@(AppOpts { .. }) = do
  _ <- setupLogging opts
  deployConfig <- parseDeployConfig opts
  urlParseResult <- (try . parseBaseUrl . T.unpack . deployUrl . deployParameters) deployConfig :: (IO (Either SomeException BaseUrl))
  case urlParseResult of
    (Left a) -> do
      errorM loggerName $ "Failed to parse proxmox API URL: " <> displayException a
      exitWith (ExitFailure 1)
    (Right proxmoxUrl) -> do
      manager <- createProxmoxManager deployConfig
      let proxmoxState = ProxmoxState proxmoxUrl manager
      pvePingResult <- defaultRetryClient' proxmoxState C.getVersion
      case pvePingResult of
        (Left e) -> do
          errorM loggerName $ "Proxmox version API request error: " <> displayException e
          exitWith (ExitFailure 1)
        (Right (ProxmoxResponse (ProxmoxVersion { proxmoxVersion = proxmoxVersion }))) -> do
          infoM loggerName $ "Found proxmox v" <> T.unpack proxmoxVersion
          case appCommand of
            Deploy -> runUpCommand proxmoxState deployConfig
            Destroy -> runDownCommand proxmoxState deployConfig
