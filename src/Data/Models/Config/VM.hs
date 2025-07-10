{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Config.VM 
  ( ConfigVM(..)
  , ConfigVMNetwork(..)
  , isTemplateVM
  ) where

import Api.Proxmox.Models.NetworkInterface
import Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Text as T

data ConfigVMNetwork = ConfigVMNetwork
  { configVMNetworkName :: !String
  , configVMNetworkFirewall :: !Bool
  , configVMDeviceType :: !NetworkInterfaceType
  , configVMNetworkTag :: !(Maybe String)
  , configVMNetworkNumber :: !(Maybe Int)
  } deriving (Show, Eq)

instance FromJSON ConfigVMNetwork where
  parseJSON (String networkName) = pure $ ConfigVMNetwork (T.unpack networkName) True VIRTIO Nothing Nothing
  parseJSON (Object v) = ConfigVMNetwork 
    <$> v .: "name"
    <*> v .:? "firewall" .!= True
    <*> v .:? "type" .!= VIRTIO
    <*> v .:? "tag"
    <*> v .:? "number"
  parseJSON _ = error "ConfigVMNetwork has invalid type"

data ConfigVM = TemplatedConfigVM 
  { configVMParentTemplate :: !String
  , configVMName :: !String
  , configVMID :: !(Maybe Int)
  , configVMDelay :: !Int
  , configVMNetworks :: !(Maybe [ConfigVMNetwork])
  } | RawVM 
  { configVMName :: !String
  , configVMID :: !(Maybe Int)
  , configVMDelay :: !Int
  } deriving (Show, Eq)

instance FromJSON ConfigVM where
  parseJSON = withObject "ConfigVM" $ \v -> case KM.lookup "clone_from" v of
    Nothing -> RawVM 
      <$> v .: "name"
      <*> v .:? "vmid"
      <*> v .:? "delay" .!= 0
    (Just (String _)) -> TemplatedConfigVM
      <$> v .: "clone_from"
      <*> v .: "name"
      <*> v .:? "vmid"
      <*> v .:? "delay" .!= 0
      <*> v .:? "networks" .!= Nothing
    _anyOtherType -> fail "clone_from field has incorrect value type!"

isTemplateVM :: ConfigVM -> Bool
isTemplateVM (TemplatedConfigVM {}) = True
isTemplateVM _ = False
