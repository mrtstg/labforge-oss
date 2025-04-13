module App.Types 
  ( AppOpts(..)
  , AppCommand(..)
  ) where

import Data.Text (Text)

data AppOpts = AppOpts 
  { configFile :: !(Maybe FilePath)
  , optsToken :: !(Maybe Text)
  , appCommand :: !AppCommand
  } deriving Show

data AppCommand = Deploy | Destroy deriving Show
