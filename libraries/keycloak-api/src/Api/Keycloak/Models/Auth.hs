{-# LANGUAGE OverloadedLists   #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api.Keycloak.Models.Auth
  ( AuthPayload(..)
  , generateAuthUrl
  , generateAuthUrlFromString
  ) where

import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as LBS
import           Data.Functor               ((<&>))
import qualified Data.HashMap.Strict        as M
import           Data.Text
import           Servant.Client
import           Web.FormUrlEncoded

data AuthPayload = OpenIDCode
  { reqState       :: !(Maybe Text)
  , reqRedirectUri :: !Text
  , reqClientID    :: !Text
  } deriving Show

instance ToJSON AuthPayload where
  toJSON (OpenIDCode { .. }) = object
    [ "state" .= reqState
    , "redirect_uri" .= reqRedirectUri
    , "client_id" .= reqClientID
    ]

instance FromJSON AuthPayload where
  parseJSON = withObject "AuthPayload" $ \v -> OpenIDCode
    <$> v .: "state"
    <*> v .: "redirect_uri"
    <*> v .: "client_id"

instance ToForm AuthPayload where
  toForm (OpenIDCode { .. }) = (Form . M.fromList) $
    [ (pack "scope", ["openid"])
    , ("response_type", ["code"])
    , ("client_id", [reqClientID])
    , ("redirect_uri", [reqRedirectUri])
    ] ++ state where
      state = case reqState of
        Nothing  -> []
        (Just v) -> [("state", [v])]

generateAuthUrl :: BaseUrl -> AuthPayload -> String
generateAuthUrl url payload = showBaseUrl url <> "?" <> (LBS.unpack . urlEncodeAsForm) payload

generateAuthUrlFromString :: String -> AuthPayload -> IO String
generateAuthUrlFromString url payload = parseBaseUrl url <&> flip generateAuthUrl payload
