{-# LANGUAGE DataKinds #-}
module Api.Keycloak.Client
  ( validateToken
  , grantToken
  , getRealmRoles
  , createRealmRole
  , deleteRealmRole
  , getRealmGroups
  , getRealmGroups'
  , getAllRealmGroups
  , getGroupMembers
  , getGroupMembers'
  , getAllGroupMembers
  , getUserGroups
  , getAllUserGroups
  , getUserBriefInfo
  ) where

import           Api.Keycloak
import           Api.Keycloak.Models
import           Api.Keycloak.Models.Group
import           Api.Keycloak.Models.Introspect
import           Api.Keycloak.Models.Role
import           Api.Keycloak.Models.Token
import           Api.Keycloak.Models.User
import           Control.Monad.Except           (throwError)
import           Control.Monad.IO.Class
import           Control.Monad.Reader
import           Data.Aeson
import           Data.Functor                   ((<&>))
import           Data.List                      (intercalate)
import qualified Data.Map                       as M
import           Data.Proxy
import           Data.Text                      (Text, isInfixOf, pack)
import           GHC.Generics
import           Network.HTTP.Types             (Status (..))
import           Servant.API
import           Servant.Client
import qualified Servant.Client.Streaming       as S

api :: Proxy KeycloakAPI
api = Proxy

validateToken
  :<|> grantToken
  :<|> getRealmRoles
  :<|> createRealmRole'
  :<|> deleteRealmRole'
  :<|> getRealmGroups'
  :<|> getGroupMembers'
  :<|> getUserGroups'
  :<|> getUserBriefInfo = client api

noContentStatusWrapper :: ClientM a -> ClientM ()
noContentStatusWrapper req = do
  state <- ask
  res <- liftIO $ runClientM req state
  case res of
    (Right _) -> pure ()
    (Left exception@(FailureResponse _ (Response { responseStatusCode = status, responseBody = body }))) -> do
      let stCode = statusCode status
      if stCode >= 200 && stCode < 300 then pure () else throwError exception
    (Left otherException) -> throwError otherException

getRealmGroups :: Text -> Int -> BearerWrapper -> ClientM [FoundGroup]
getRealmGroups realmName pageNumber = do
  getRealmGroups' realmName (Just $ 100 * (pageNumber - 1)) (Just 100)

getAllRealmGroups :: Text -> BearerWrapper -> ClientM [FoundGroup]
getAllRealmGroups realmName token = let
  helper :: [FoundGroup] -> Int -> ClientM [FoundGroup]
  helper acc pageNumber = do
    groups <- getRealmGroups realmName pageNumber token
    if null groups then pure acc else helper (acc ++ groups) (pageNumber + 1)
  in helper [] 1

getGroupMembers :: Text -> Text -> Int -> BearerWrapper -> ClientM [BriefUser]
getGroupMembers realmName group pageNumber = do
  getGroupMembers' realmName group (Just True) (Just $ 100 * (pageNumber - 1)) (Just 100)

getAllGroupMembers :: Text -> Text -> BearerWrapper -> ClientM [BriefUser]
getAllGroupMembers realmName group token = let
  helper :: [BriefUser] -> Int -> ClientM [BriefUser]
  helper acc pageNumber = do
    users <- getGroupMembers realmName group pageNumber token
    if null users then pure acc else helper (acc ++ users) (pageNumber + 1)
  in helper [] 1

getUserGroups :: Text -> Text -> Int -> BearerWrapper -> ClientM [FoundGroup]
getUserGroups realmName user pageNumber = getUserGroups' realmName user (Just True) (Just $ 100 * (pageNumber - 1)) (Just 100)

getAllUserGroups :: Text -> Text -> BearerWrapper -> ClientM [FoundGroup]
getAllUserGroups realmName user token = let
  helper :: [FoundGroup] -> Int -> ClientM [FoundGroup]
  helper acc pageNumber = do
    users <- getUserGroups realmName user pageNumber token
    if null users then pure acc else helper (acc ++ users) (pageNumber + 1)
  in helper [] 1

createRealmRole realm token req = do
  noContentStatusWrapper (createRealmRole' realm token req)

deleteRealmRole realm roleId' token = noContentStatusWrapper (deleteRealmRole' realm roleId' token)
