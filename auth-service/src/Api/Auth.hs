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
{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE TypeOperators     #-}
module Api.Auth
  ( authAPI
  , authServer
  , AuthAPI
  ) where

import           Api.Keycloak.Client
import           Api.Keycloak.Models
import           Api.Keycloak.Models.Auth
import           Api.Keycloak.Models.Group
import           Api.Keycloak.Models.Introspect
import           Api.Keycloak.Models.Role
import           Api.Keycloak.Models.Token
import           Api.Keycloak.Models.User
import           Api.Keycloak.Utils
import           Api.Redirect
import           Api.Retry
import           Auth
import           Auth.Schema
import           Config
import           Control.Monad                  ((>=>))
import           Control.Monad.Catch
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Char8          as BS
import           Data.Maybe
import           Data.Text                      (Text)
import qualified Data.Text                      as T
import           Models.JSONError
import           Network.HTTP.Types.URI         (urlEncode)
import           Servant
import           Servant.Client

authAPI :: Proxy AuthAPI
authAPI = Proxy

authServer :: ServerT AuthAPI AppT
authServer =
  authClient'
  :<|> validateTokenEndpoint
  :<|> getRoles
  :<|> createRole
  :<|> deleteRole
  :<|> getCapabilities
  :<|> loginEndpoint
  :<|> logoutEndpoint
  :<|> loginFailEndpoint
  :<|> loginCallback
  :<|> getPagedGroups
  :<|> getAllGroups
  :<|> getPagedMembers
  :<|> getAllMembers
  :<|> getPagedUserGroups
  :<|> getFullUserGroups
  :<|> getUserBriefInfo'
  :<|> redirectOnPortal

getUserBriefInfo' :: Text -> BearerWrapper -> AppT BriefUser
getUserBriefInfo' userId (BearerWrapper token) = do
  _ <- requireRealmRoles token ["user-read"]
  Config { .. } <- ask
  withTokenVariable'' $ \t -> runClientApp keycloakEnv $ getUserBriefInfo keycloakRealm userId (BearerWrapper t)

getPagedUserGroups :: Text -> BearerWrapper -> Maybe Int -> AppT [FoundGroup]
getPagedUserGroups userId (BearerWrapper token) pageN = do
  let page = max 0 $ fromMaybe 1 pageN
  _ <- requireRealmRoles token ["user-read"]
  Config { .. } <- ask
  withTokenVariable'' $ \t -> runClientApp keycloakEnv $ getUserGroups keycloakRealm userId page (BearerWrapper t)

getFullUserGroups :: Text -> BearerWrapper -> AppT [FoundGroup]
getFullUserGroups userId (BearerWrapper token) = do
  _ <- requireRealmRoles token ["user-read"]
  Config { .. } <- ask
  withTokenVariable'' $ \t -> runClientApp keycloakEnv  $ getAllUserGroups keycloakRealm userId (BearerWrapper t)

getPagedGroups :: BearerWrapper -> Maybe Int -> AppT [FoundGroup]
getPagedGroups (BearerWrapper token) pageN = do
  _ <- requireRealmRoles token ["group-read"]
  Config { .. } <- ask
  withTokenVariable'' $ \t -> runClientApp keycloakEnv $ getRealmGroups keycloakRealm (fromMaybe 1 pageN) (BearerWrapper t)

getAllGroups :: BearerWrapper -> AppT [FoundGroup]
getAllGroups (BearerWrapper token) = do
  _ <- requireRealmRoles token ["group-read"]
  Config { .. } <- ask
  withTokenVariable'' $ \t -> runClientApp keycloakEnv $ getAllRealmGroups keycloakRealm (BearerWrapper t)

getPagedMembers :: Text -> BearerWrapper -> Maybe Int -> AppT [BriefUser]
getPagedMembers groupName' (BearerWrapper token) pageN = do
  _ <- requireRealmRoles token ["user-read"]
  Config { .. } <- ask
  withTokenVariable'' $ \t -> do
    allGroups <- getAllGroups (BearerWrapper t)
    case filter ((==) groupName' . groupName) allGroups of
      [] -> sendJSONError err404 (JSONError "GroupNotFound" "Group is not found" Null)
      (FoundGroup { groupID=groupID }:_) -> do
        runClientApp keycloakEnv $ getGroupMembers keycloakRealm groupID (fromMaybe 1 pageN) (BearerWrapper t)

getAllMembers :: Text -> BearerWrapper -> AppT [BriefUser]
getAllMembers groupName' (BearerWrapper token) = do
  _ <- requireRealmRoles token ["user-read"]
  Config { .. } <- ask
  withTokenVariable'' $ \t -> do
    allGroups <- getAllGroups (BearerWrapper t)
    case filter ((==) groupName' . groupName) allGroups of
      [] -> sendJSONError err404 (JSONError "GroupNotFound" "Group is not found" Null)
      (FoundGroup { groupID=groupID }:_) -> do
        runClientApp keycloakEnv $ getAllGroupMembers keycloakRealm groupID (BearerWrapper t)

getCapabilities :: BearerWrapper -> AppT [Text]
getCapabilities (BearerWrapper token) = do
  tokenData <- requireToken token
  return $ tokenRealmRoles tokenData

loginEndpoint :: Maybe Text -> AppT ()
loginEndpoint (Just redirectFlag) = do
  Config { .. } <- ask
  let payload = OpenIDCode {reqState=Just $ "redirect=" <> redirectFlag, reqRedirectUri="/api/auth/callback", reqClientID=authClient}
  let link = generateAuthUrl (keycloakUrl { baseUrlPath = baseUrlPath keycloakUrl <> "/realms/" <> T.unpack keycloakRealm <> "/protocol/openid-connect/auth" }) payload
  tempRedirectTo link
loginEndpoint Nothing = loginEndpoint (Just "/")

logoutEndpoint :: AppT ()
logoutEndpoint = do
  Config { .. } <- ask
  let url = keycloakUrl { baseUrlPath = baseUrlPath keycloakUrl <> "/realms/" <> T.unpack keycloakRealm <> "/protocol/openid-connect/logout" }
  tempRedirectTo (showBaseUrl url)

redirectOnPortal :: AppT ()
redirectOnPortal = do
  Config { .. } <- ask
  let url = keycloakUrl { baseUrlPath = baseUrlPath keycloakUrl <> "/admin/" <> T.unpack keycloakRealm <> "/console/" }
  tempRedirectTo (showBaseUrl url)

loginFailEndpoint :: AppT ()
loginFailEndpoint = tempRedirectTo "/api/auth/login"

loginCallback :: Maybe Text -> Maybe Text -> AppT ()
loginCallback (Just code) (Just url) = do
  Config { .. } <- ask
  let redirectUrl = (T.unpack . T.replace "redirect=" "") url
  tokenResp <- defaultRetryClientC keycloakEnv $ grantToken keycloakRealm (AuthorizationCodeRequest {reqCode=code, reqClientSecret=authSecret, reqClientID=authClient, reqRedirectUri="/api/auth/callback"})
  case tokenResp of
    (Left e) -> do
      $(logError) $ "Failed to request user access token: " <> (T.pack . show) e
      loginFailEndpoint
    (Right (GrantResponse { .. })) -> do
      throwError $ err307 { errHeaders = [("Location", BS.pack redirectUrl), ("Set-Cookie", BS.pack $ "token=" <> T.unpack accessToken <> "; Max-Age=" <> show authCookieAge <> "; Path=/")] }
loginCallback _ _ = loginFailEndpoint

createRole :: BearerWrapper -> RoleCreateRequest -> AppT ()
createRole (BearerWrapper token) req = do
  _ <- requireRealmRoles token ["role-manage"]
  Config { .. } <- ask
  resp <- withTokenVariable' $ \serviceToken -> do
    runClientApp keycloakEnv $ createRealmRole keycloakRealm (BearerWrapper serviceToken) req
  case resp of
    (Left e) -> do
      $(logError) $ "Failed to create role: " <> (T.pack . show) e
      sendJSONError err500 (JSONError "keycloakError" "Error response from keycloak" Null)
    (Right _) -> pure ()

deleteRole :: BearerWrapper -> Text -> AppT ()
deleteRole (BearerWrapper token) roleDeleteName = do
  _ <- requireRealmRoles token ["role-manage"]
  Config { .. } <- ask
  roles <- withTokenVariable'' $ \t -> do
    runClientApp keycloakEnv $ getRealmRoles keycloakRealm (BearerWrapper t)
  case filter ((==) roleDeleteName . roleName) roles of
    [] -> do
      $(logWarn) $ "Role with name " <> (T.pack . show) roleDeleteName <> " not found"
      pure ()
    (RealmRole { .. }:_) -> do
      withTokenVariable'' $ \t -> do
        runClientApp keycloakEnv $ deleteRealmRole keycloakRealm roleId (BearerWrapper t)

getRoles :: BearerWrapper -> AppT [RealmRole]
getRoles (BearerWrapper token) = do
  _ <- requireRealmRoles token ["role-read"]
  Config { .. } <- ask
  roles <- withTokenVariable' $ \serviceToken -> do
    runClientApp keycloakEnv $ getRealmRoles keycloakRealm (BearerWrapper serviceToken)
  case roles of
    (Left e) -> do
      $(logError) $ "Failed to get realm roles: " <> (T.pack . show) e
      sendJSONError err500 (JSONError "keycloakError" "Error response from keycloak" Null)
    (Right resp) -> pure resp

validateTokenEndpoint :: Text -> BearerWrapper -> AppT IntrospectResponse
validateTokenEndpoint requiredToken (BearerWrapper token) = do
  _ <- requireRealmRoles token ["validate-users"]
  lookupToken requiredToken

authClient' :: GrantRequest -> AppT GrantResponse
authClient' req = do
  env <- asks keycloakEnv
  realm <- asks keycloakRealm
  resp <- runClientApp env $ grantToken realm req
  case resp of
    (Left e) -> do
      $(logError) $ "Failed to execute grant request: " <> (T.pack . show) e
      sendJSONError err500 (JSONError "keycloakError" "Error response from keycloak" Null)
    (Right resp) -> pure resp
