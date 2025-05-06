module Utils 
  ( findExistingFile
  , defaultConfigFiles
  , returnFirstDuplicate
  ) where

import System.Directory

returnFirstDuplicate :: (Eq a) => [a] -> Maybe a
returnFirstDuplicate = helper [] where
  helper :: (Eq a) => [a] -> [a] -> Maybe a
  helper acc (el:els) = if el `elem` acc then Just el else helper (el:acc) els
  helper _ [] = Nothing

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
