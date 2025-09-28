{-# LANGUAGE OverloadedLists   #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api.Keycloak.Models.Introspect
  ( IntrospectRequest(..)
  , IntrospectResponse(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap  as KM
import           Data.Text          (Text)
import           Web.FormUrlEncoded
import           Web.HttpApiData

data IntrospectRequest = IntrospectRequest
  { reqToken        :: !Text
  , reqClientID     :: !Text
  , reqClientSecret :: !Text
  } deriving Show

instance FromJSON IntrospectRequest where
  parseJSON = withObject "IntrospectRequest" $ \v -> IntrospectRequest
    <$> v .: "token"
    <*> v .: "client_id"
    <*> v .: "client_secret"

instance ToJSON IntrospectRequest where
  toJSON (IntrospectRequest { .. }) = object
    [ "token" .= reqToken
    , "client_id" .= reqClientID
    , "client_secret" .= reqClientSecret
    ]

instance ToForm IntrospectRequest where
  toForm (IntrospectRequest { .. }) =
    [ ("token", toQueryParam reqToken)
    , ("client_id", toQueryParam reqClientID)
    , ("client_secret", toQueryParam reqClientSecret)
    ]

data IntrospectResponse = InactiveToken |
  ActiveToken
  { tokenRealmRoles        :: ![Text]
  , tokenAccountRoles      :: ![Text]
  , tokenScope             :: !Text
  , tokenUsername          :: !Text
  , tokenPreferredUsername :: !Text
  , tokenName              :: !(Maybe Text)
  , tokenEmail             :: !(Maybe Text)
  , tokenUUID              :: !(Maybe Text)
  , tokenSessionID         :: !(Maybe Text)
  } deriving Show

instance FromJSON IntrospectResponse where
  parseJSON = withObject "IntrospectResponse" $ \v -> case KM.lookup "active" v of
    Just (Bool False) -> pure InactiveToken
    Just (Bool True)  -> ActiveToken
      <$> (v .: "realm_access" >>= (.: "roles"))
      <*> (v .: "resource_access" >>= (.: "account") >>= (.: "roles"))
      <*> v .: "scope"
      <*> v .: "username"
      <*> v .: "preferred_username"
      <*> v .:? "name"
      <*> v .:? "email"
      <*> v .:? "sub"
      <*> v .:? "sid"
    _anyOther -> fail $ "IntrospectResponse got invalid active value: " <> show _anyOther

instance ToJSON IntrospectResponse where
  toJSON InactiveToken = object ["active" .= Bool False]
  toJSON ActiveToken { .. } = object
    [ "active" .= Bool True
    , "realm_access" .= object [ "roles" .= tokenRealmRoles ]
    , "resource_access" .= object [ "account" .= object [ "roles" .= tokenAccountRoles ]]
    , "scope" .= tokenScope
    , "username" .= tokenUsername
    , "preferred_username" .= tokenPreferredUsername
    , "name" .= tokenName
    , "email" .= tokenEmail
    , "sub" .= tokenUUID
    , "sid" .= tokenSessionID
    ]
