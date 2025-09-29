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
{-# LANGUAGE TemplateHaskell   #-}
module Auth
  ( lookupToken
  , requireToken
  , requireRealmRoles
  ) where

-- TODO: retry if failed

import           Api.Keycloak.Client
import           Api.Keycloak.Models.Introspect
import           Config
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import           Data.Text                      (Text, pack, unpack)
import           Models.JSONError
import           Redis.Common
import           Servant.Server
import           System.CPUTime

lookupToken :: Text -> AppT IntrospectResponse
lookupToken token = let
  getTokenResp = do
    startTime <- liftIO getCPUTime
    Config { .. } <- ask
    tokenResp <- runClientApp keycloakEnv $ validateToken keycloakRealm (IntrospectRequest {reqToken=token, reqClientSecret=keycloakClientSecret, reqClientID=keycloakClientID})
    case tokenResp of
      (Left _) -> sendJSONError err401 (JSONError "unauthorized" "Failed to check token" Null)
      (Right resp) -> do
        $(logDebug) $ "Cached new token value!"
        endTime <- liftIO getCPUTime
        let diff = (fromIntegral (endTime - startTime)) / (10^12)
        $(logDebug) $ "Got token data in " <> (pack . show) diff
        (pure . Just) resp
  in do
    v <- getOrCacheJsonValue (Just 10) (unpack token) getTokenResp
    $(logDebug) $ "Checking token " <> token <> ":" <> (pack . show) v
    case v of
      (Left _) -> sendJSONError err401 (JSONError "unauthorized" "Failed to check token" Null)
      (Right resp) -> pure resp


requireToken :: Text -> AppT IntrospectResponse
requireToken token = do
  r <- lookupToken token
  case r of
    InactiveToken -> sendJSONError err401 (JSONError "unauthorized" "Inactive token" Null)
    d@(ActiveToken {}) -> pure d

requireRealmRoles :: Text -> [Text] -> AppT IntrospectResponse
requireRealmRoles token roles = do
  t <- requireToken token
  case t of
    ~(ActiveToken { .. }) -> do
      if all (`elem` tokenRealmRoles) roles then
        pure t
      else sendJSONError err403 (JSONError "unauthorized" "Insufficent permissions" Null)
