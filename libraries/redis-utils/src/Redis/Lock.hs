{-# LANGUAGE TemplateHaskell #-}
module Redis.Lock
  ( checkRedisLock
  , redisLockWrapper
  , redisRateLockWrapper
  , redisLockWrapper_
  ) where

import           Control.Monad
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Functor           ((<&>))
import           Data.Maybe
import           Data.Text              (pack)
import           Redis.Common

checkRedisLock :: (MonadLogger m, MonadIO m, RedisConnection a, MonadReader a m) => String -> m Bool
checkRedisLock k = ($(logDebug) . pack $ "Checking lock key " <> k) >> getValue' k <&> isNothing

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
