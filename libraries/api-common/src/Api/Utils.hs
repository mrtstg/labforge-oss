{-# LANGUAGE OverloadedStrings #-}
module Api.Utils
  ( tryDecodeError
  , DecodeResult(..)
  ) where

import           Data.Aeson
import           Data.ByteString
import qualified Data.ByteString.Lazy.Char8 as LBS
import           Models.JSONError
import           Network.HTTP.Types
import           Servant.Client

data DecodeResult a = DecodedResult a | DecodedError Int JSONError | UndecodedError Int ByteString | OtherError ClientError deriving Show

tryDecodeError :: Either ClientError a -> DecodeResult a
tryDecodeError (Right a) = DecodedResult a
tryDecodeError (Left (FailureResponse _ (Response { responseStatusCode = status, responseBody = body }))) = do
  case eitherDecode body of
    (Left _) -> UndecodedError (statusCode status) (LBS.toStrict body)
    (Right err@(JSONError {})) -> DecodedError (statusCode status) err
tryDecodeError (Left e) = OtherError e
