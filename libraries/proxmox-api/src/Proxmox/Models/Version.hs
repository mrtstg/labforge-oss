{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
module Proxmox.Models.Version
  ( ProxmoxVersion(..)
  , ProxmoxConsole(..)
  ) where

import           Data.Aeson
import           Data.Text

data ProxmoxVersion = ProxmoxVersion
  { proxmoxRelease :: !Text
  , proxmoxRepoID  :: !Text
  , proxmoxVersion :: !Text
  , proxmoxConsole :: !(Maybe ProxmoxConsole)
  } deriving (Show, Eq, Ord)

instance FromJSON ProxmoxVersion where
  parseJSON = withObject "ProxmoxVersion" $ \v -> ProxmoxVersion
    <$> v .: "release"
    <*> v .: "repoid"
    <*> v .: "version"
    <*> v .:? "console"

data ProxmoxConsole = Applet | VV | HTML5 | XTermJS | Unknown Text deriving (Show, Eq, Ord)

instance FromJSON ProxmoxConsole where
  parseJSON = withText "ProxmoxConsole" $ \case
    "applet" -> pure Applet
    "vv" -> pure VV
    "html5" -> pure HTML5
    "xtermjs" -> pure XTermJS
    anyOther -> pure (Unknown anyOther)
