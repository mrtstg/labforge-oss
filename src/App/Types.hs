module App.Types 
  ( AppOpts(..)
  , AppCommand(..)
  ) where

data AppOpts = AppOpts 
  { configFile :: !(Maybe FilePath)
  , appCommand :: !AppCommand
  } deriving Show

data AppCommand = Deploy | Destroy deriving Show
