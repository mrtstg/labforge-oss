{-# LANGUAGE OverloadedStrings #-}
module Api.Proxmox.Models (ProxmoxResponse(..)) where

import Data.Aeson

newtype ProxmoxResponse t = ProxmoxResponse t deriving Show

instance (FromJSON t) => FromJSON (ProxmoxResponse t) where
  parseJSON = withObject "ProxmoxResponse" $ \v -> ProxmoxResponse
    <$> v .: "data"
