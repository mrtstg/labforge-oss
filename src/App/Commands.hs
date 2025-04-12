{-# LANGUAGE RecordWildCards #-}
module App.Commands 
  ( runCommand
  ) where

import Utils
import App.Types
import Control.Exception
import System.Exit
import Data.List (intercalate)
import Data.Models.Config

runUpCommand :: AppOpts -> IO ()
runUpCommand opts = putStrLn "Up!"

runDownCommand :: AppOpts -> IO ()
runDownCommand opts = putStrLn "Down!"

runCommand :: AppOpts -> IO ()
runCommand opts@(AppOpts {appCommand=appCommand, configFile=configFile}) = let
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
        (Left parseError) -> putStrLn $ displayException parseError
        (Right deployConfig) -> do
          print deployConfig
          case appCommand of
            Deploy -> runUpCommand opts
            Destroy -> runDownCommand opts
