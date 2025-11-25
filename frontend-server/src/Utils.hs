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
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Utils where

import           Api
import           Api.Keycloak.Models.Introspect
import           Config
import           Control.Concurrent.STM         (atomically)
import           Control.Concurrent.STM.TVar
import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8     as LBS
import qualified Data.Map                       as M
import           Data.Maybe
import           Data.Text                      (Text)
import           Data.Text.Encoding
import           Deployment.Models.Deployment
import           Text.Printf

prettyEncode :: (ToJSON a) => a -> String
prettyEncode = printf "%s" . decodeUtf8 . LBS.toStrict . encode

addMessageToSession :: IntrospectResponse -> Text -> AppT ()
addMessageToSession InactiveToken _      = pure ()
addMessageToSession (ActiveToken { .. }) msg = do
  case tokenUUID of
    Nothing -> pure ()
    (Just uuid) -> do
      messages <- asks sessionMessages >>= liftIO . readTVarIO
      case M.lookup uuid messages of
        Nothing -> do
          asks sessionMessages >>= \x -> liftIO . atomically $ modifyTVar x (M.insert uuid [msg])
        (Just oldValue) -> do
          asks sessionMessages >>= \x -> liftIO . atomically $ modifyTVar x (M.insert uuid $ oldValue ++ [msg])
      pure ()

iteratePagedResponse :: (Int -> AppT (PagedResponse [a])) -> AppT [a]
iteratePagedResponse f' = helper f' 1 [] where
  helper :: (Int -> AppT (PagedResponse [a])) -> Int -> [a] -> AppT [a]
  helper f page acc = do
    v <- f page
    if hasNextPages page v then helper f (page + 1) (responseObjects v ++ acc) else pure (responseObjects v ++ acc)

prettyDeployStatus :: DeploymentStatus -> String
prettyDeployStatus Deployed   = "Развернут"
prettyDeployStatus Deploying  = "Развертывается"
prettyDeployStatus Destroying = "Удаляется"
prettyDeployStatus Failed     = "Ошибка"
prettyDeployStatus Created    = "Ожидает развертывания"

unpackPage :: Maybe Int -> Int
unpackPage = max 1 . fromMaybe 1

hasNextPages :: Int -> PagedResponse a -> Bool
hasNextPages page (PagedResponse {responseTotal=totalAmount, responsePageSize=pageSize }) =
  totalAmount - page * pageSize > 0
