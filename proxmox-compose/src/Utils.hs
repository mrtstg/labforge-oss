module Utils
  ( findExistingFile
  , defaultConfigFiles
  , returnFirstDuplicate
  , commonErrorStdoutHandler
  , commonErrorStdoutHandler'
  ) where

import           Servant.Client
import           System.Directory
import           System.Exit
import           System.Log.Logger

type LoggerName = String

returnFirstDuplicate :: (Eq a) => [a] -> Maybe a
returnFirstDuplicate = helper [] where
  helper :: (Eq a) => [a] -> [a] -> Maybe a
  helper acc (el:els) = if el `elem` acc then Just el else helper (el:acc) els
  helper _ []         = Nothing

defaultConfigFiles :: [FilePath]
defaultConfigFiles = ["proxmox-compose.yaml", "proxmox-compose.yml"]

-- find first existing file and provides results for other before
findExistingFile :: [FilePath] -> IO (Maybe FilePath, [FilePath])
findExistingFile = f [] where
  f :: [FilePath] -> [FilePath] -> IO (Maybe FilePath, [FilePath])
  f acc [] = return (Nothing, acc)
  f acc (path:paths) = do
    fileExists <- doesFileExist path
    if fileExists then return (Just path, acc) else f (acc ++ [path]) paths

commonErrorStdoutHandler' :: (Show e) => LoggerName -> IO (Either e a) -> IO a
commonErrorStdoutHandler' loggerName res = commonErrorStdoutHandler loggerName res show

commonErrorStdoutHandler :: (Show e) => LoggerName -> IO (Either e a) -> (e -> String) -> IO a
commonErrorStdoutHandler loggerName res errorF = do
  v <- res
  case v of
    (Left e) -> do
      errorM loggerName (errorF e)
      exitWith (ExitFailure 1)
    (Right r) -> return r
