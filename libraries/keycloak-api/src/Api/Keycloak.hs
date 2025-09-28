{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}
module Api.Keycloak
  ( KeycloakAPI
  ) where

import           Api.Keycloak.Models
import           Api.Keycloak.Models.Group
import           Api.Keycloak.Models.Introspect
import           Api.Keycloak.Models.Role
import           Api.Keycloak.Models.Token
import           Api.Keycloak.Models.User
import           Data.Text
import           Servant.API

type RealmCapture = Capture "realm" Text
type RoleIDCapture = Capture "roleId" Text
type GroupIDCapture = Capture "groupId" Text
type UserIDCapture = Capture "userId" Text
type AuthHeader = Header' '[Required] "Authorization" BearerWrapper
type FirstParam = QueryParam "first" Int
type MaxParam = QueryParam "max" Int
type BriefParam = QueryParam "briefRepresentation" Bool

type KeycloakAPI = "realms" :> RealmCapture :> "protocol" :> "openid-connect" :> "token" :> "introspect" :> ReqBody '[FormUrlEncoded] IntrospectRequest :> Post '[JSON] IntrospectResponse
  :<|> "realms" :> RealmCapture :> "protocol" :> "openid-connect" :> "token" :> ReqBody '[FormUrlEncoded] GrantRequest :> Post '[JSON] GrantResponse
  :<|> "admin" :> "realms" :> RealmCapture :> "roles" :> AuthHeader :> Get '[JSON] [RealmRole]
  :<|> "admin" :> "realms" :> RealmCapture :> "roles" :> AuthHeader :> ReqBody '[JSON] RoleCreateRequest :> Post '[JSON] ()
  :<|> "admin" :> "realms" :> RealmCapture :> "roles-by-id" :> RoleIDCapture :> AuthHeader :> Delete '[JSON] ()
  :<|> "admin" :> "realms" :> RealmCapture :> "groups" :> FirstParam :> MaxParam :> AuthHeader :> Get '[JSON] [FoundGroup]
  :<|> "admin" :> "realms" :> RealmCapture :> "groups" :> GroupIDCapture :> "members" :> BriefParam :> FirstParam :> MaxParam :> AuthHeader :> Get '[JSON] [BriefUser]
  :<|> "admin" :> "realms" :> RealmCapture :> "users" :> UserIDCapture :> "groups" :> BriefParam :> FirstParam :> MaxParam :> AuthHeader :> Get '[JSON] [FoundGroup]
  :<|> "admin" :> "realms" :> RealmCapture :> "users" :> UserIDCapture :> AuthHeader :> Get '[JSON] BriefUser
