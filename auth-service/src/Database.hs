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
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE EmptyDataDecls             #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE StandaloneDeriving         #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE TypeOperators              #-}
{-# LANGUAGE UndecidableInstances       #-}

module Database where

import           Config
import           Control.Monad.IO.Class
import           Control.Monad.Reader
import           Data.Aeson
import           Database.Persist.Sql
import           Database.Persist.TH

--share [ mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
--User
--  name String
--  password String
--  deriving Show
-- |]

--instance ToJSON User where
--  toJSON (User { .. }) = object
--    [ "name" .= userName
--    , "password" .= userPassword
--    ]
--
--doMigration :: SqlPersistT IO ()
--doMigration = runMigration migrateAll
--
--runDB :: (MonadReader Config m, MonadIO m) => SqlPersistT IO b -> m b
--runDB query = do
--  pool <- asks configDBPool
--  liftIO $ runSqlPool query pool
