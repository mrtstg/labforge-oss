{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api.Keycloak.Models.Role
  ( RealmRole(..)
  , RoleCreateRequest(..)
  ) where

import           Data.Aeson
import           Data.Text  (Text)

data RealmRole = RealmRole
  { roleId          :: !Text
  , roleName        :: !Text
  , roleDescription :: !Text
  } deriving (Show, Eq)

instance FromJSON RealmRole where
  parseJSON = withObject "RealmRole" $ \v -> RealmRole
    <$> v .: "id"
    <*> v .: "name"
    <*> v .:? "description" .!= ""

instance ToJSON RealmRole where
  toJSON (RealmRole { .. }) = object
    [ "id" .= roleId
    , "name" .= roleName
    , "description" .= roleDescription
    ]

data RoleCreateRequest = RoleCreateRequest
  { reqRoleName :: !Text
  } deriving (Show, Eq)

instance FromJSON RoleCreateRequest where
  parseJSON = withObject "RoleCreateRequest" $ \v -> RoleCreateRequest
    <$> v .: "name"

instance ToJSON RoleCreateRequest where
  toJSON (RoleCreateRequest { .. }) = object ["name" .= String reqRoleName]
