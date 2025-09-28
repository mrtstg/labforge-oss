{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api where

import           Api.Keycloak.Models
import           Data.Aeson
import           Servant.API

type AuthHeader = Header' '[Required] "Authorization" BearerWrapper

data PagedResponse t = PagedResponse
  { responsePageSize :: !Int
  , responseTotal    :: !Int
  , responseObjects  :: !t
  } deriving Show

instance (ToJSON t) => ToJSON (PagedResponse t) where
  toJSON (PagedResponse { .. }) = object
    [ "pageSize" .= responsePageSize
    , "total" .= responseTotal
    , "objects" .= responseObjects
    ]

instance (FromJSON t) => FromJSON (PagedResponse t) where
  parseJSON = withObject "PagedResponse" $ \v -> PagedResponse
    <$> v .: "pageSize"
    <*> v .: "total"
    <*> v .: "objects"
