{- Copyright (C) 2025 Ilya Zamaratskikh

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, see <http://www.gnu.org/licenses>. -}
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TypeOperators       #-}
module Api.Jobservice
  ( jobserviceServer
  ) where

import           Api.Keycloak.Models
import           Auth.Token
import           Config
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as LBS
import           Data.Text                  (Text)
import qualified Data.Text                  as T
import           Jobservice.Models
import           Jobservice.Schema
import           Models.JSONError
import           Network.AMQP
import           Redis.Common
import           Servant

jobserviceServer :: ServerT JobserviceAPI AppT
jobserviceServer = sendMessage :<|> getHeldImages :<|> getImageUsage

sendMessage :: JobserviceMessage -> BearerWrapper -> AppT ()
sendMessage msgPayload (BearerWrapper token) = do
  _ <- requireRealmRoles token ["jobservice-send"]
  -- TODO: future validation
  r <- asks rabbitConnection
  chan <- liftIO $ openChannel r
  let msg = newMsg { msgBody = encode msgPayload, msgDeliveryMode = Just NonPersistent }
  _ <- liftIO $ publishMsg chan "jobserviceExchange" "" msg
  liftIO $ closeChannel chan
  pure ()

getImageUsage :: Text -> BearerWrapper -> AppT [JobserviceImageUsageData]
getImageUsage imageName (BearerWrapper token) = do
  _ <- requireManyRealmRoles token [["image-view"], ["image-admin"]]
  redisV <- getValue' . jobserviceUsedImageKey . T.unpack $ imageName
  case redisV of
    Nothing        -> pure []
    (Just payload) -> do
      case eitherDecode (LBS.fromStrict payload) of
        (Left e) -> do
          $(logError) $ "Image usage decode error: " <> (T.pack . show) e
          sendJSONError err500 (JSONError "internalError" "Failed to decode data" Null)
        (Right (usages :: [JobserviceImageUsageData])) -> pure usages

getHeldImages :: BearerWrapper -> AppT [String]
getHeldImages (BearerWrapper token) = do
  _ <- requireManyRealmRoles token [["image-view"], ["image-admin"]]
  redisV <- getValue' jobserviceUsedImagesKey
  case redisV of
    Nothing        -> sendJSONError err404 (JSONError "notFound" "" Null)
    (Just payload) -> do
      case eitherDecode (LBS.fromStrict payload) of
        (Left e) -> do
          $(logError) $ "Held images decode error: " <> (T.pack . show) e
          sendJSONError err500 (JSONError "internalError" "Failed to decode data" Null)
        (Right (images :: [String])) -> pure images
