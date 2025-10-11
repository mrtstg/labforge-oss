{-# LANGUAGE TemplateHaskell #-}
module Utils
  ( findExistingFile
  , defaultConfigFiles
  , returnFirstDuplicate
  , commonErrorStdoutHandler
  , commonErrorStdoutHandler'
  ) where

import           Control.Monad.IO.Class
import           Control.Monad.Logger
import qualified Data.Text              as T
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

commonErrorStdoutHandler' :: (Show e) => LoggingT IO (Either e a) -> LoggingT IO a
commonErrorStdoutHandler' res = commonErrorStdoutHandler res (T.pack . show)

commonErrorStdoutHandler :: LoggingT IO (Either e a) -> (e -> T.Text) -> LoggingT IO a
commonErrorStdoutHandler res errorF = do
  v <- res
  case v of
    (Left e) -> do
      $(logError) (errorF e)
      liftIO $ exitWith (ExitFailure 1)
    (Right r) -> return r
