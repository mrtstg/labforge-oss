{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
module Api.Keycloak.Token
  ( TokenVariableFunctions(..)
  , TokenVariable
  , HasTokenVariable(..)
  , createTokenVar
  , withTokenVariable
  ) where

import           Control.Concurrent.STM
import           Control.Monad.Reader

data TokenVariableFunctions a = TokenFunctions
  { tokenValidateF :: a -> IO Bool
  , tokenIssueF    :: IO (Either String a)
  }

class HasTokenVariable t a where
  getTokenVariable :: t -> TokenVariable a
  getTokenFunctions :: t -> TokenVariableFunctions a

type TokenVariable a = TVar (Maybe a)

createTokenVar :: IO (TokenVariable a)
createTokenVar = newTVarIO Nothing

withTokenVariable :: (MonadIO m, HasTokenVariable t a, MonadReader t m) => (a -> m b) -> m (Either String b)
withTokenVariable f = do
  (TokenFunctions validateToken issueToken) <- asks getTokenFunctions
  v <- asks getTokenVariable
  currentToken' <- liftIO $ readTVarIO v
  case currentToken' of
    Nothing -> do
      newToken <- liftIO issueToken
      case newToken of
        (Left e) -> pure $ Left e
        (Right tokenV) -> do
          (liftIO . atomically) $ writeTVar v (Just tokenV)
          withTokenVariable f
    (Just tokenV) -> do
      tokenValid <- liftIO $ validateToken tokenV
      if not tokenValid then do
        newToken <- liftIO issueToken
        case newToken of
          (Left e) -> pure $ Left e
          (Right tokenV) -> do
            (liftIO . atomically) $ writeTVar v (Just tokenV)
            withTokenVariable f
      else do
        res <- f tokenV
        (pure . Right) res
