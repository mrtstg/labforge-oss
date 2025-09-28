{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Proxmox.Models.VMClone
  ( ProxmoxVMCloneParams(..)
  ) where

import           Data.Aeson
import           Data.Text  (Text)

-- TODO: implement all fields: https://pve.proxmox.com/pve-docs/api-viewer/#/nodes/{node}/qemu/{vmid}/clone
data ProxmoxVMCloneParams = ProxmoxVMCloneParams
  { proxmoxVMCloneNewID       :: !Int
  --, proxmoxVMCloneNode        :: !Text -- field is omitted when decoding to JSON
  , proxmoxVMCloneVMID        :: !Int -- field is omitted when decoding to JSON
  , proxmoxVMCloneDescription :: !(Maybe Text)
  , proxmoxVMCloneName        :: !(Maybe Text)
  , proxmoxVMCloneSnapname    :: !(Maybe Text)
  , proxmoxVMCloneStorage     :: !(Maybe Text)
  , proxmoxVMCloneTarget      :: !(Maybe Text)
  } deriving (Show, Eq, Ord)

instance ToJSON ProxmoxVMCloneParams where
  toJSON (ProxmoxVMCloneParams { .. }) = object $
    [ "newid" .= proxmoxVMCloneNewID ]
    ++ vmName
    ++ vmSnapname
    ++ vmDescription
    ++ vmStorage
    ++ vmTarget where
      vmStorage = case proxmoxVMCloneStorage of
        Nothing            -> []
        (Just "")          -> []
        (Just storageName) -> ["storage" .= storageName, "full" .= True]
      vmName = case proxmoxVMCloneName of
        Nothing        -> []
        (Just vmName') -> [ "name" .= vmName' ]
      vmSnapname = case proxmoxVMCloneSnapname of
        Nothing            -> []
        (Just vmSnapname') -> [ "snapname" .= vmSnapname' ]
      vmDescription = case proxmoxVMCloneDescription of
        Nothing               -> []
        (Just vmDescription') -> [ "description" .= vmDescription' ]
      vmTarget = case proxmoxVMCloneTarget of
        Nothing          -> []
        (Just vmTarget') -> [ "target" .= vmTarget' ]
