{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.Cluster
  ( ClusterResource(..)
  , isQEMUResource
  , findQEMUResourceById
  , findQEMUTemplateById
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap     as KV
import           Data.List             (find)
import           Data.Text             (Text, pack)
import           Proxmox.Models.VM
import           Proxmox.Utils.Parsers

findQEMUTemplateById :: Int -> [ClusterResource] -> Maybe ClusterResource
findQEMUTemplateById vmid resources = do
  case findQEMUResourceById vmid resources of
    (Just r@(QEMUResource { resourceTemplate = True })) -> Just r
    (Just _)                                            -> Nothing
    Nothing                                             -> Nothing

findQEMUResourceById :: Int -> [ClusterResource] -> Maybe ClusterResource
findQEMUResourceById vmid = find ((==) (pack $ "qemu/" <> show vmid) . resourceId) . filter isQEMUResource

isQEMUResource :: ClusterResource -> Bool
isQEMUResource (QEMUResource {}) = True
isQEMUResource _                 = False

-- note: if status: unknown fields can be missing
data ClusterResource = QEMUResource
  { resourceId       :: !Text
  , resourceVMID     :: !Int
  , resourceNode     :: !Text
  , resourceName     :: !(Maybe Text)
  , resourceStatus   :: !ProxmoxVMStatus
  , resourceTemplate :: !Bool
  } | OtherResource -- TODO: temporary placeholder
  deriving (Show, Eq, Ord)

instance FromJSON ClusterResource where
  parseJSON = withObject "ClusterResource" $ \v -> case KV.lookup "type" v of
    (Just (String "qemu")) -> QEMUResource <$> v .: "id" <*> notNullWrapper (KV.lookup "vmid" v) intStringParser <*> v .: "node" <*> v .:? "name" <*> v .: "status" <*> nullDefaultWrapper (KV.lookup "template" v) False variableBooleanParser
    _anyOther -> pure OtherResource
