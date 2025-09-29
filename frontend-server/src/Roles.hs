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
module Roles where

import           Api.Keycloak.Models
import           Api.Keycloak.Models.Introspect
import           Auth.Token
import           Config
import           Data.Aeson
import           Data.Text                      (Text)
import           Models.JSONError
import           Servant.Server

grafanaAdmin :: Text
grafanaAdmin = "grafana-admin"

grafanaEditor :: Text
grafanaEditor = "grafana-editor"

grafanaViewer :: Text
grafanaViewer = "grafana-viewer"

deploymentCreator :: Text
deploymentCreator = "deployment-create"

deploymentAdmin :: Text
deploymentAdmin = "deployment-admin"

imageViewer :: Text
imageViewer = "image-view"

imageAdmin :: Text
imageAdmin = "image-admin"

canCreateImages :: IntrospectResponse -> Bool
canCreateImages InactiveToken        = False
canCreateImages (ActiveToken { .. }) = imageAdmin `elem` tokenRealmRoles

canViewImages :: Maybe BearerWrapper -> AppT IntrospectResponse
canViewImages = flip requireManyRealmRoles' [[imageViewer], [imageAdmin]]

canCreateDeployments :: Maybe BearerWrapper -> AppT IntrospectResponse
canCreateDeployments = flip requireManyRealmRoles' [[deploymentAdmin], [deploymentCreator]]

requireManyRealmRoles' :: Maybe BearerWrapper -> [[Text]] -> AppT IntrospectResponse
requireManyRealmRoles' Nothing _ = sendJSONError err401 (JSONError "" "" Null)
requireManyRealmRoles' (Just (BearerWrapper token)) roles = requireManyRealmRoles token roles

requireToken' :: Maybe BearerWrapper -> AppT IntrospectResponse
requireToken' Nothing = sendJSONError err401 (JSONError "" "" Null)
requireToken' (Just (BearerWrapper token)) = requireToken token

lookupToken' :: Maybe BearerWrapper -> AppT IntrospectResponse
lookupToken' Nothing                      = pure InactiveToken
lookupToken' (Just (BearerWrapper token)) = lookupToken token
