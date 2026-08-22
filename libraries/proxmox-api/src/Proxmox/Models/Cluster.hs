{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.Cluster
  ( ClusterResource(..)
  , isQEMUResource
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap as KV
import           Data.Text
import           Proxmox.Models.VM

isQEMUResource :: ClusterResource -> Bool
isQEMUResource (QEMUResource {}) = True
isQEMUResource _                 = False

data ClusterResource = QEMUResource
  { resourceId     :: !Text
  , resourceNode   :: !Text
  , resourceName   :: !Text
  , resourceStatus :: !ProxmoxVMStatus
  } | OtherResource -- TODO: temporary placeholder
  deriving (Show, Eq, Ord)

instance FromJSON ClusterResource where
  parseJSON = withObject "ClusterResource" $ \v -> case KV.lookup "type" v of
    (Just (String "qemu")) -> QEMUResource <$> v .: "id" <*> v .: "node" <*> v .:? "name" .!= "" <*> v .: "status"
    _anyOther -> pure OtherResource
