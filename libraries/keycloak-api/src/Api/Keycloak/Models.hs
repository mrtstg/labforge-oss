{-# LANGUAGE OverloadedStrings #-}
module Api.Keycloak.Models
  ( BearerWrapper(..) ) where

import qualified Data.ByteString.Char8 as BS
import           Data.String
import           Data.Text
import           Servant.API

newtype BearerWrapper = BearerWrapper Text deriving (Show, Eq)

instance ToHttpApiData BearerWrapper where
  toHeader (BearerWrapper token) = (BS.pack . unpack) $ "Bearer " <> token

instance FromHttpApiData BearerWrapper where
  parseHeader = Right . BearerWrapper . strip . replace "Bearer" "" . pack . BS.unpack

instance IsString BearerWrapper where
  fromString = (BearerWrapper . pack)
