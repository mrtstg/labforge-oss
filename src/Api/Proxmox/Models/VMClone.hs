{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api.Proxmox.Models.VMClone 
  ( ProxmoxVMCloneParams(..)
  ) where

import           Data.Aeson
import           Data.Text  (Text)

-- TODO: implement all fields: https://pve.proxmox.com/pve-docs/api-viewer/#/nodes/{node}/qemu/{vmid}/clone
data ProxmoxVMCloneParams = ProxmoxVMCloneParams
  { getVMCloneNewID       :: !Int
  , getVMCloneNode        :: !Text -- field is omitted when decoding to JSON
  , getVMCloneVMID        :: !Int -- field is omitted when decoding to JSON
  , getVMCloneDescription :: !(Maybe Text)
  , getVMCloneName        :: !(Maybe Text)
  , getVMCloneSnapname    :: !(Maybe Text)
  , getVMCloneStorage     :: !(Maybe Text)
  } deriving (Show, Eq)

instance ToJSON ProxmoxVMCloneParams where
  toJSON (ProxmoxVMCloneParams { .. }) = object $
    [ "newid" .= getVMCloneNewID ]
    ++ vmName
    ++ vmSnapname
    ++ vmDescription
    ++ vmStorage where
      vmStorage = case getVMCloneStorage of
        Nothing            -> []
        (Just "")          -> []
        (Just storageName) -> ["storage" .= storageName, "full" .= True]
      vmName = case getVMCloneName of
        Nothing        -> []
        (Just vmName') -> [ "name" .= vmName' ]
      vmSnapname = case getVMCloneSnapname of
        Nothing            -> []
        (Just vmSnapname') -> [ "snapname" .= vmSnapname' ]
      vmDescription = case getVMCloneDescription of
        Nothing               -> []
        (Just vmDescription') -> [ "description" .= vmDescription' ]
