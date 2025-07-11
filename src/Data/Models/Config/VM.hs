{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
module Data.Models.Config.VM 
  ( ConfigVM(..)
  , ConfigVMNetwork(..)
  , isTemplateVM
  , formatConfigVMNetwork
  ) where

import Api.Proxmox.Models.NetworkInterface
import Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Text as T
import Data.List (intercalate)
import Parsers
import Data.Maybe

data ConfigVMNetwork = ConfigVMNetwork
  { configVMNetworkName :: !String
  , configVMNetworkFirewall :: !Bool
  , configVMDeviceType :: !NetworkInterfaceType
  , configVMNetworkTag :: !(Maybe Int)
  , configVMNetworkNumber :: !(Maybe Int)
  } deriving (Show, Eq)

formatConfigVMNetwork :: ConfigVMNetwork -> Maybe (String, String)
formatConfigVMNetwork ConfigVMNetwork { .. } = case configVMNetworkNumber of
  Nothing -> Nothing
  (Just netNum) -> Just ("net" <> show netNum, intercalate "," $ 
    [ "model=" <> show configVMDeviceType
    , "firewall=" <> if configVMNetworkFirewall then "1" else "0"
    , "bridge=" <> configVMNetworkName
    ] 
    ++ ["tag=" <> (show . fromJust) configVMNetworkTag | isJust configVMNetworkTag])

instance FromJSON ConfigVMNetwork where
  parseJSON (String networkName) = pure $ ConfigVMNetwork (T.unpack networkName) True VIRTIO Nothing Nothing
  parseJSON (Object v) = ConfigVMNetwork 
    <$> v .: "name"
    <*> v .:? "firewall" .!= True
    <*> v .:? "type" .!= VIRTIO
    <*> v .:? "tag"
    <*> nullMaybeWrapper (KM.lookup "number" v) (limitedNumberParser (`elem` [0..31]) "Network number must be in range 0..32")
  parseJSON _ = error "ConfigVMNetwork has invalid type"

data ConfigVM = TemplatedConfigVM 
  { configVMParentTemplate :: !String
  , configVMName :: !String
  , configVMID :: !(Maybe Int)
  , configVMDelay :: !Int
  , configVMNetworks :: !(Maybe [ConfigVMNetwork])
  , configVMCleanNetworks :: !Bool
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
      <*> nullDefaultWrapper (KM.lookup "clean_networks" v) False variableBooleanParser
    _anyOtherType -> fail "clone_from field has incorrect value type!"

isTemplateVM :: ConfigVM -> Bool
isTemplateVM (TemplatedConfigVM {}) = True
isTemplateVM _ = False
