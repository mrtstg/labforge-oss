{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api.Keycloak.Models.User
  ( BriefUser(..)
  , briefDisplayName
  ) where

import           Data.Aeson
import           Data.Text

data BriefUser = BriefUser
  { userID        :: !Text
  , userUsername  :: !Text
  , userFirstName :: !(Maybe Text)
  , userLastName  :: !(Maybe Text)
  , userEmail     :: !(Maybe Text)
  } deriving (Show, Eq)

instance FromJSON BriefUser where
  parseJSON = withObject "BriefUser" $ \v -> BriefUser
    <$> v .: "id"
    <*> v .: "username"
    <*> v .:? "firstName"
    <*> v .:? "lastName"
    <*> v .:? "email"

instance ToJSON BriefUser where
  toJSON (BriefUser { .. }) = object
    [ "id" .= userID
    , "username" .= userUsername
    , "firstName" .= userFirstName
    , "lastName" .= userLastName
    , "email" .= userEmail
    ]

briefDisplayName :: BriefUser -> Text
briefDisplayName (BriefUser { userFirstName = Just name, userLastName = Just lname }) = name <> " " <> lname
briefDisplayName (BriefUser { userFirstName = Just name, userLastName = Nothing }) = name
briefDisplayName (BriefUser { userFirstName = _, userLastName = _, userUsername = username }) = username
