{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
module Redis.Common
  ( cacheValue
  , cacheValue'
  , deleteValue
  , getValue
  , getValue'
  , getStringValue
  , deleteValue'
  , getJsonValue'
  , getOrCacheJsonValue
  , defaultShortCacheTime
  , RedisConnection(..)
  ) where

import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Char8 as BS
import           Data.Functor          ((<&>))
import qualified Data.Text             as T
import           Data.Text.Encoding
import           Database.Redis

class RedisConnection a where
  getRedisConnection :: a -> Connection

defaultShortCacheTime :: Integer
defaultShortCacheTime = 5

cacheValue :: (MonadIO m, RedisConnection a, MonadReader a m) => BS.ByteString -> BS.ByteString -> Maybe Integer -> m ()
cacheValue key value timeout = do
  conn <- asks getRedisConnection
  _ <- (liftIO . runRedis conn) $ setOpts key value (SetOpts timeout Nothing Nothing)
  return ()

cacheValue' :: (MonadIO m, RedisConnection a, MonadReader a m) => String -> String -> Maybe Integer -> m ()
cacheValue' key value = cacheValue (BS.pack key) (BS.pack value)

deleteValue :: (MonadIO m, RedisConnection a, MonadReader a m) => BS.ByteString -> m ()
deleteValue key = do
  conn <- asks getRedisConnection
  _ <- (liftIO . runRedis conn) $ del [key]
  return ()

deleteValue' :: (MonadIO m, RedisConnection a, MonadReader a m) => String -> m ()
deleteValue' key = deleteValue (BS.pack key)

getValue :: (MonadIO m, RedisConnection a, MonadReader a m) => BS.ByteString -> m (Maybe BS.ByteString)
getValue key = do
  conn <- asks getRedisConnection
  v <- (liftIO . runRedis conn) $ get key
  return $ case v of
    (Left _) -> Nothing
    (Right res) -> case res of
      Nothing   -> Nothing
      (Just v') -> Just v'

getValue' :: (RedisConnection a, MonadReader a m, MonadIO m) => String -> m (Maybe BS.ByteString)
getValue' = getValue . encodeUtf8 . T.pack

getStringValue :: (RedisConnection a, MonadReader a m, MonadIO m) => String -> m (Maybe String)
getStringValue key = getValue' key <&> fmap BS.unpack

getJsonValue' :: (FromJSON v, RedisConnection a, MonadReader a m, MonadIO m) => String -> m (Either String v)
getJsonValue' key = do
  v' <- getValue' key
  case v' of
    Nothing -> return $ Left "No data!"
    (Just v) -> do
      return $ eitherDecode (BS.fromStrict v)

getOrCacheJsonValue :: (MonadIO m, RedisConnection a, MonadReader a m, FromJSON v, ToJSON v) => Maybe Integer -> String -> m (Maybe v) -> m (Either String v)
getOrCacheJsonValue timeout key valueF = let
  cacheF :: (ToJSON v, MonadIO m, RedisConnection a, MonadReader a m) => m (Maybe v) -> m (Either String v)
  cacheF valueF' = do
    v' <- valueF'
    case v' of
      Nothing  -> return $ Left "Failed to get value!"
      (Just v) -> do
        _ <- cacheValue ((encodeUtf8 . T.pack) key) (BS.toStrict $ encode v) timeout
        return $ Right v
  in do
    cachedData <- getJsonValue' key
    case cachedData of
      (Left _)  -> cacheF valueF
      (Right v) -> return $ Right v
