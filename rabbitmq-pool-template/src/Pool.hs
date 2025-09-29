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
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
module Pool
  ( AsyncPool(..)
  , createPool
  , putTask
  ) where

import           Config
import           Control.Concurrent
import           Control.Concurrent.Async
import           Control.Concurrent.QSemN
import           Control.Concurrent.STM
import           Control.Concurrent.STM.TQueue
import           Control.Exception
import           Control.Monad
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Data.Text                     (Text, pack)

data AsyncPool a = AsyncPool
  { poolThreads  :: ![Async ()]
  , poolCallback :: a -> AppT ()
  , poolQueue    :: !(TQueue a)
  , poolSem      :: !QSemN
  }

createPool :: (a -> AppT ()) -> (AppT () -> IO ()) -> Int -> IO (AsyncPool a)
createPool f appToIO tasks = let
  tF :: QSemN -> TQueue a -> (a -> AppT ()) -> Int -> AppT ()
  tF sem q callback workerNum  = do
    $(logInfo) $ "Stated worker " <> (pack . show) workerNum
    forever $ do
      $(logDebug) $ "Worker " <> (pack . show) workerNum <> " reading query"
      task <- (liftIO . atomically) $ tryReadTQueue q
      case task of
        Nothing  -> (liftIO . threadDelay) 1000000
        (Just t) -> liftIO $ bracket_ (waitQSemN sem 1) (signalQSemN sem 1) (appToIO $ callback t)
  in do
  sem <- newQSemN tasks
  q <- newTQueueIO
  threads <- mapM (async . appToIO . tF sem q f) [1..tasks]
  pure $ AsyncPool threads f q sem

putTask :: (MonadIO m) => AsyncPool a -> a -> m ()
putTask (AsyncPool { .. }) t = (liftIO . atomically) $ writeTQueue poolQueue t
