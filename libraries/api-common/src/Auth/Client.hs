module Auth.Client
  ( postGrantRequest
  , postValidateRequest
  , getRoles
  , postRoles
  , deleteRole
  , getTokenCapabilities
  , getPagedGroups
  , getAllGroups
  , getPagedGroupMembers
  , getAllGroupMembers
  , getUserBriefInfo
  ) where

import           Auth.Schema
import           Servant
import           Servant.Client

api :: Proxy AuthAPI
api = Proxy

postGrantRequest
  :<|> postValidateRequest
  :<|> getRoles
  :<|> postRoles
  :<|> deleteRole
  :<|> getTokenCapabilities
  :<|> _
  :<|> _
  :<|> _
  :<|> _
  :<|> getPagedGroups
  :<|> getAllGroups
  :<|> getPagedGroupMembers
  :<|> getAllGroupMembers
  :<|> getPagedUserGroups
  :<|> getAllUserGroups
  :<|> getUserBriefInfo
  :<|> _ = client api
