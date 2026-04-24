{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
module Redis.Lock
  ( checkRedisLock
  , redisLockWrapper
  , redisRateLockWrapper
  , redisLockWrapper_
  , redisNXLockWrapper
  ) where

import           Control.Monad
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Reader
import qualified Data.ByteString.Char8  as BS
import           Data.Functor           ((<&>))
import           Data.Maybe
import           Data.Text              (pack)
import           Database.Redis
import           Redis.Common

checkRedisLock :: (MonadLogger m, MonadIO m, RedisConnection a, MonadReader a m) => String -> m Bool
checkRedisLock k = ($(logDebug) . pack $ "Checking lock key " <> k) >> getValue' k <&> isNothing

redisNXLockWrapper :: (MonadLogger m, MonadIO m, RedisConnection a, MonadReader a m) => String -> Integer -> IO Integer -> m r -> m r -> m r
redisNXLockWrapper lockKey lockTime getTime onLocked onFree = do
  $(logDebug) . pack $ "Trying NX key " <> lockKey
  ts <- liftIO $ getTime <&> \x -> x + lockTime
  redis <- asks getRedisConnection
  r <- (liftIO . runRedis redis) (sendRequest (map BS.pack ["SET", lockKey, show ts, "NX", "EX", show lockTime]))
  case r of
    (Left (Bulk Nothing)) -> do
      $(logError) . pack $ "NX key " <> lockKey <> " is taken"
      onLocked
    (Right Ok) -> do
      x <- onFree
      $(logDebug) . pack $ "Unlocking key " <> lockKey
      (_ :: Either Reply Integer) <- (liftIO . runRedis redis) $ eval "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end" [BS.pack lockKey] [BS.pack . show $ ts]
      pure x
    _otherStatus -> ($(logWarn) . pack $ "Unknown status: " <> show _otherStatus) >> onLocked

redisLockWrapper_ :: (MonadLogger m, MonadIO m, RedisConnection a, MonadReader a m) => String -> Integer -> m b -> m c -> m ()
redisLockWrapper_ lockKey lockTime onLocked onFree = do
  lockFree <- checkRedisLock lockKey
  if lockFree then do
    $(logDebug) . pack $ "Holding lock key " <> lockKey <> " for " <> show lockTime <> " s."
    cacheValue' lockKey "lock" (Just lockTime)
    onFree >> ($(logDebug) . pack $ "Unlocking key " <> lockKey) >> deleteValue' lockKey >> pure ()
  else do
    $(logDebug) . pack $ "Key " <> lockKey <> " is locked"
    void onLocked

redisLockWrapper :: (MonadLogger m, MonadIO m, RedisConnection a, MonadReader a m) => String -> Integer -> m r -> m r -> m r
redisLockWrapper lockKey lockTime onLocked onFree = do
  lockFree <- checkRedisLock lockKey
  if lockFree then do
    $(logDebug) . pack $ "Holding lock key " <> lockKey <> " for " <> show lockTime <> " s."
    cacheValue' lockKey "lock" (Just lockTime)
    onFree >>= \x -> ($(logDebug) . pack $ "Unlocking key " <> lockKey) >> deleteValue' lockKey >> pure x
  else do
    $(logDebug) . pack $ "Key " <> lockKey <> " is locked"
    onLocked

redisRateLockWrapper :: (MonadLogger m, MonadIO m, RedisConnection a, MonadReader a m) => String -> Integer -> m r -> m r -> m r
redisRateLockWrapper lockKey lockTime onLocked onFree = do
  lockFree <- checkRedisLock lockKey
  if lockFree then do
    cacheValue' lockKey "lock" (Just lockTime)
    onFree
  else onLocked
