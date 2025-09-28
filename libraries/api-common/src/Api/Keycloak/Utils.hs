{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedLists   #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}
module Api.Keycloak.Utils
  ( unwrapError
  , withTokenVariable'
  , withTokenVariable''
  ) where

import           Api.Keycloak.Token
import           Api.Utils
import           Control.Monad.Except
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Char8       as BS
import qualified Data.ByteString.Lazy.Char8  as LBS
import           Data.Text
import           Models.JSONError
import           Network.HTTP.Client.Conduit (defaultRequest)
import           Network.HTTP.Types
import           Servant
import           Servant.Client

-- TODO: solve this (and test it)
upliftErrorToClient :: (Show a) => Either a b -> Either ClientError b
upliftErrorToClient (Left e) = Left $ FailureResponse undefined
  (Response { responseStatusCode=Status 500 "", responseHttpVersion=http10, responseHeaders=[], responseBody=(LBS.pack . show) e})
upliftErrorToClient (Right v) = pure v

unwrapError :: (MonadError ServerError m, MonadLogger m) => DecodeResult a -> m a
unwrapError (DecodedResult a) = pure a
unwrapError e = do
  case e of
    (UndecodedError status body) -> do
      $(logDebug) $ "Got undecoded error " <> (pack . show) status <> " : " <> (pack . show) body
      sendJSONError (ServerError {errReasonPhrase="", errHeaders=[], errHTTPCode=status, errBody=""}) (JSONError "internalError" (BS.unpack body) Null)
    (DecodedError status err) -> do
      $(logDebug) $ "Got decoded error " <> (pack . show) status <> ": " <> (pack . show) err
      sendJSONError (ServerError {errReasonPhrase="", errHeaders=[], errHTTPCode=status, errBody=""}) err
    (OtherError err) -> do
      $(logDebug) $ "Got other error: " <> (pack . show) err
      sendJSONError err500 (JSONError "internalError" "Internal server error" Null)

withTokenVariable' :: (MonadIO m, HasTokenVariable t a, MonadReader t m, MonadError ServerError m, MonadLogger m) => (a -> m b) -> m b
withTokenVariable' f = withTokenVariable f >>= unwrapError . tryDecodeError . upliftErrorToClient

withTokenVariable'' :: (MonadIO m, HasTokenVariable t a, MonadReader t m, MonadError ServerError m, MonadLogger m) => (a -> m (Either ClientError b)) -> m b
withTokenVariable'' f = withTokenVariable' f >>= unwrapError . tryDecodeError . upliftErrorToClient
