{-# LANGUAGE OverloadedLists   #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api.Keycloak.Models.Token
  ( GrantRequest(..)
  , GrantResponse(..)
  ) where

import           Data.Aeson
import qualified Data.Aeson.KeyMap  as KM
import           Data.Text          (Text)
import           Web.FormUrlEncoded
import           Web.HttpApiData    (ToHttpApiData (toQueryParam))

data GrantRequest = AuthorizationCodeRequest
  { reqCode         :: !Text
  , reqRedirectUri  :: !Text
  , reqClientID     :: !Text
  , reqClientSecret :: !Text
  } | ClientCredentialsRequest
  { reqClientID     :: !Text
  , reqClientSecret :: !Text
  } deriving Show

instance FromJSON GrantRequest where
  parseJSON = withObject "GrantRequest" $ \v -> case KM.lookup "grant_type" v of
    (Just (String "authorization_code")) -> AuthorizationCodeRequest
      <$> v .: "code"
      <*> v .: "redirect_uri"
      <*> v .: "client_id"
      <*> v .: "client_secret"
    (Just (String "client_credentials")) -> ClientCredentialsRequest
      <$> v .: "client_id"
      <*> v .: "client_secret"
    _anyOther -> fail "Unsupported grant_type value!"

instance ToJSON GrantRequest where
  toJSON (AuthorizationCodeRequest { .. }) = object
    [ "grant_type" .= String "authorization_code"
    , "code" .= reqCode
    , "redirect_uri" .= reqRedirectUri
    , "client_id" .= reqClientID
    , "client_secret" .= reqClientSecret
    ]
  toJSON (ClientCredentialsRequest { .. }) = object
    [ "grant_type" .= String "client_credentials"
    , "client_id" .= reqClientID
    , "client_secret" .= reqClientSecret
    ]

instance ToForm GrantRequest where
  toForm AuthorizationCodeRequest { .. } =
    [ ("grant_type", "authorization_code")
    , ("redirect_uri", toQueryParam reqRedirectUri)
    , ("code", toQueryParam reqCode)
    , ("client_id", toQueryParam reqClientID)
    , ("client_secret", toQueryParam reqClientSecret)
    ]
  toForm ClientCredentialsRequest { .. } =
    [ ("grant_type", "client_credentials")
    , ("client_id", toQueryParam reqClientID)
    , ("client_secret", toQueryParam reqClientSecret)
    ]

data GrantResponse = GrantResponse
  { accessToken        :: !Text
  , accessTokenExpires :: !Int
  , tokenScope         :: !Text
  } deriving Show

instance FromJSON GrantResponse where
  parseJSON = withObject "GrantResponse" $ \v -> GrantResponse
    <$> v .: "access_token"
    <*> v .: "expires_in"
    <*> v .: "scope"

instance ToJSON GrantResponse where
  toJSON (GrantResponse { .. }) = object
    [ "access_token" .= accessToken
    , "expires_in" .= accessTokenExpires
    , "scope" .= tokenScope
    ]
