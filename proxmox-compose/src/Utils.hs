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
