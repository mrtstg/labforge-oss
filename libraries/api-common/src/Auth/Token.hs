{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
module Auth.Token
  ( genericTokenFunctions
  , lookupToken
  , requireToken
  , requireRealmRoles
  , requireManyRealmRoles
  ) where

import           Api.Keycloak.Models
import qualified Api.Keycloak.Models.Introspect as I
import           Api.Keycloak.Models.Token
import           Api.Keycloak.Token
import           Api.Keycloak.Utils
import           Auth.Client
import           Control.Monad.Except
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import           Data.Text
import           Models.JSONError
import           Servant.Client
import           Servant.Server
import           Service.Environment
import           Utils.Time
import           Web.JWT

lookupToken :: (MonadIO m, MonadLogger m, HasTokenVariable s Text, ServiceEnvironment s, MonadReader s m, MonadError ServerError m) => Text -> m I.IntrospectResponse
lookupToken token = do
  env <- asks $ getEnvFor AuthService
  withTokenVariable'' $ \t -> (liftIO . flip runClientM env) (postValidateRequest token (BearerWrapper t))

requireToken :: (MonadIO m, MonadLogger m, HasTokenVariable s Text, ServiceEnvironment s, MonadReader s m, MonadError ServerError m) => Text -> m I.IntrospectResponse
requireToken token = do
  r <- lookupToken token
  case r of
    I.InactiveToken -> sendJSONError err401 (JSONError "unauthorized" "Inactive token" $ object [ "message" .= String "Ваша сессия истекла. Обновите страницу или войдите повторно." ])
    d@(I.ActiveToken {}) -> pure d

requireRealmRoles :: (MonadIO m, MonadLogger m, HasTokenVariable s Text, ServiceEnvironment s, MonadReader s m, MonadError ServerError m) => Text -> [Text] -> m I.IntrospectResponse
requireRealmRoles token roles = requireManyRealmRoles token [roles]

requireManyRealmRoles :: (MonadIO m, MonadLogger m, HasTokenVariable s Text, ServiceEnvironment s, MonadReader s m, MonadError ServerError m) => Text -> [[Text]] -> m I.IntrospectResponse
requireManyRealmRoles token rolesMap = do
  t <- requireToken token
  case t of
    ~(I.ActiveToken { .. }) -> do
      if Prelude.any (Prelude.all (`Prelude.elem` tokenRealmRoles)) rolesMap then
        pure t
      else sendJSONError err403 (JSONError "unauthorized" "Insufficent permissions" $ object [ "message" .= String "У вас нет прав на выполнение данного действия"])

genericTokenFunctions :: (Loc -> LogSource -> LogLevel -> LogStr -> IO ()) -> (Text, Text) -> ClientEnv -> TokenVariableFunctions Text
genericTokenFunctions logF (cID, cSecret) env = TokenFunctions
    { tokenValidateF=(\t -> runLoggingT (validate t) logF)
    , tokenIssueF=runLoggingT issue logF } where
  validate :: (MonadIO m, MonadLogger m) => Text -> m Bool
  validate token = do
    let tokenTime = fmap (fmap (floor . secondsSinceEpoch) . Web.JWT.exp . claims) . Web.JWT.decode $ token
    case tokenTime of
      Nothing -> do
        $(logWarn) "Failed to decode service token"
        pure False
      (Just Nothing) -> do
        $(logWarn) "Issued service token has no exp attribute"
        pure False
      (Just (Just expTime)) -> do
        currentTime <- getUnixIntTime
        return $ expTime > currentTime + 30
  issue :: (MonadIO m, MonadLogger m) => m (Either String Text)
  issue = do
    r <- (liftIO . flip runClientM env) $ postGrantRequest (ClientCredentialsRequest {reqClientSecret=cSecret, reqClientID=cID})
    case r of
      (Left e) -> do
        $(logError) $ pack $ "Failed to issue token: " <> show e
        (pure . Left . show) e
      (Right (GrantResponse {accessToken=accessToken})) -> (pure . pure) accessToken
