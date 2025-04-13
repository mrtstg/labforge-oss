{-# LANGUAGE RecordWildCards #-}
module App.Commands 
  ( runCommand
  ) where

import Data.Text (Text)
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
import Api.Ssl (noSSLManager)
import Network.HTTP.Client (newManager, defaultManagerSettings)

runUpCommand :: AppOpts -> IO ()
runUpCommand opts = putStrLn "Up!"

runDownCommand :: AppOpts -> IO ()
runDownCommand opts = putStrLn "Down!"

parseDeployConfig :: AppOpts -> IO DeployConfig
parseDeployConfig AppOpts { .. } = let
 configFiles' = case configFile of
  Nothing -> defaultConfigFiles
  (Just path) -> path:defaultConfigFiles
 in do
  (configPath', checkedPaths) <- findExistingFile configFiles'
  case configPath' of
    Nothing -> do
      putStrLn $ "No available config files found. Checked: " <> intercalate "," checkedPaths
      exitWith (ExitFailure 1)
    (Just configPath) -> do
      configParseResult <- decodeDeployConfig configPath
      case configParseResult of
        (Left parseError) -> do
          putStrLn $ displayException parseError
          exitWith (ExitFailure 1)
        (Right deployConfig') -> do
          let deployConfig = updateDeployConfigToken optsToken deployConfig'
          case (deployToken . deployParameters) deployConfig of
            Nothing -> do
              putStrLn "Access token is not provided in file or command. Exiting..."
              exitWith (ExitFailure 1)
            _tokenExists -> do
              return deployConfig

substituteProxmoxToken :: DeployConfig -> (Maybe Text -> ClientM a) -> ClientM a
substituteProxmoxToken (DeployConfig { deployParameters = DeployParams { deployToken = token' } }) m = case token' of
  (Just token) -> (m . Just) $ T.pack "PVEAPIToken=" <> token
  Nothing -> m Nothing

runCommand :: AppOpts -> IO ()
runCommand opts@(AppOpts { .. }) = do
  deployConfig <- parseDeployConfig opts
  urlParseResult <- (try . parseBaseUrl . T.unpack . deployUrl . deployParameters) deployConfig :: (IO (Either SomeException BaseUrl))
  case urlParseResult of
    (Left a) -> do
      putStrLn $ "Failed to parse proxmox API URL: " <> displayException a
      exitWith (ExitFailure 1)
    (Right proxmoxUrl) -> do
      manager <- if (deployIgnoreSSL . deployParameters) deployConfig then noSSLManager else newManager defaultManagerSettings
      let proxmoxState = ProxmoxState proxmoxUrl manager
      pvePingResult <- runProxmoxClient' proxmoxState (substituteProxmoxToken deployConfig C.getVersion)
      case pvePingResult of
        (Left e) -> do
          putStrLn $ "Proxmox version API request error: " <> displayException e
          exitWith (ExitFailure 1)
        (Right (ProxmoxResponse (ProxmoxVersion { proxmoxVersion = proxmoxVersion }))) -> do
          putStrLn $ "Found proxmox v" <> T.unpack proxmoxVersion
          case appCommand of
            Deploy -> runUpCommand opts
            Destroy -> runDownCommand opts
