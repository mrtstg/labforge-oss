module Utils 
  ( findExistingFile
  , defaultConfigFiles
  ) where

import System.Directory

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
