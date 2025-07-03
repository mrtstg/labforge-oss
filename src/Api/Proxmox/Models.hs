{-# LANGUAGE OverloadedStrings #-}
module Api.Proxmox.Models 
  ( ProxmoxResponse(..)
  , NumericBoolWrapper(..)
  ) where

import Data.Aeson
import Servant.API

newtype ProxmoxResponse t = ProxmoxResponse t deriving Show

instance (FromJSON t) => FromJSON (ProxmoxResponse t) where
  parseJSON = withObject "ProxmoxResponse" $ \v -> ProxmoxResponse
    <$> v .: "data"

newtype NumericBoolWrapper = NumericBoolWrapper Bool deriving (Show, Eq)

instance ToHttpApiData NumericBoolWrapper where
  toQueryParam (NumericBoolWrapper True) = "1"
  toQueryParam (NumericBoolWrapper False) = "0"
