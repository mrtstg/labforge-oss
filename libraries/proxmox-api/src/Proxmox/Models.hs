{-# LANGUAGE OverloadedStrings #-}
module Proxmox.Models
  ( ProxmoxResponse(..)
  , NumericBoolWrapper(..)
  ) where

import           Data.Aeson
import           Servant.API

data ProxmoxResponse t = ProxmoxResponse { proxmoxData :: !t, proxmoxMessage :: !(Maybe Value) } deriving Show

instance (FromJSON t) => FromJSON (ProxmoxResponse t) where
  parseJSON = withObject "ProxmoxResponse" $ \v -> ProxmoxResponse
    <$> v .: "data"
    <*> v .:? "message"

newtype NumericBoolWrapper = NumericBoolWrapper Bool deriving (Show, Eq)

instance ToHttpApiData NumericBoolWrapper where
  toQueryParam (NumericBoolWrapper True)  = "1"
  toQueryParam (NumericBoolWrapper False) = "0"
