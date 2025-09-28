{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api.Keycloak.Models.Group
  ( FoundGroup(..)
  ) where

import           Data.Aeson
import           Data.Text

data FoundGroup = FoundGroup
  { groupName :: !Text
  , groupID   :: !Text
  } deriving (Show, Eq)

instance FromJSON FoundGroup where
  parseJSON = withObject "FoundGroup" $ \v -> FoundGroup
    <$> v .: "name"
    <*> v .: "id"

instance ToJSON FoundGroup where
  toJSON (FoundGroup { .. }) = object
    [ "name" .= groupName
    , "id" .= groupID
    ]
