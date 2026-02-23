module Redis.Lock
  ( checkRedisLock
  , redisLockWrapper
  , redisRateLockWrapper
  ) where

import           Control.Monad.IO.Class
import           Control.Monad.Reader
import           Data.Functor           ((<&>))
import           Data.Maybe
import           Redis.Common

checkRedisLock :: (MonadIO m, RedisConnection a, MonadReader a m) => String -> m Bool
checkRedisLock k = getValue' k <&> isNothing

redisLockWrapper :: (MonadIO m, RedisConnection a, MonadReader a m) => String -> Integer -> m a -> m a -> m a
redisLockWrapper lockKey lockTime onLocked onFree = do
  lockFree <- checkRedisLock lockKey
  if lockFree then do
    cacheValue' lockKey "lock" (Just lockTime)
    r <- onFree
    deleteValue' lockKey
    pure r
  else onLocked

redisRateLockWrapper :: (MonadIO m, RedisConnection a, MonadReader a m) => String -> Integer -> m a -> m a -> m a
redisRateLockWrapper lockKey lockTime onLocked onFree = do
  lockFree <- checkRedisLock lockKey
  if lockFree then do
    cacheValue' lockKey "lock" (Just lockTime)
    onFree
  else onLocked
