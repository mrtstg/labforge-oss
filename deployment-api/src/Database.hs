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
import qualified Data.ByteString.Char8           as BS
import qualified Data.ByteString.Lazy.Char8      as LBS
import qualified Data.Map                        as M
import           Data.Text
import qualified Data.Text                       as T
import           Database.Persist.Sql
import           Database.Persist.TH
import           Deployment.Models.Deployment
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.VM
import           Proxmox.Deploy.Types

share [ mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
MachineTemplateData
  name Text
  NameUnique
  deriving Show Eq
DeploymentTemplateData
  ownerId Text
  title Text
  vms [ConfigVM] sqltype=jsonb
  availableVMs [Text] sqltype=jsonb
  existingNetworks [Text] sqltype=jsonb
  UniqueTitle
  deriving Show Eq
DeploymentInstanceData
  Id Text Primary
  parent DeploymentTemplateDataId OnDeleteRestrict OnUpdateCascade
  ownerId Text
  deployConfig DeployConfig Maybe
  state DeploymentStatus
  logs [Text] sqltype=jsonb
  networkNamesMap (M.Map String String) sqltype=jsonb
  vmLinks (M.Map String String) sqltype=jsonb
  deriving Show
UsedVMID
  num Int Primary
  usedBy DeploymentInstanceDataId OnDeleteCascade OnUpdateCascade
  UniqueNum
  deriving Show
UsedDisplay
  num Int
  nodeName Text
  usedBy DeploymentInstanceDataId OnDeleteCascade OnUpdateCascade
  Primary num nodeName
  deriving Show
UsedBridges
  name Text Primary
  usedBy DeploymentInstanceDataId OnDeleteCascade OnUpdateCascade
  UniqueName
  deriving Show
|]

instance PersistField TransactionData where
  toPersistValue = toPersistValueJSON
  fromPersistValue = fromPersistValueJSON

instance PersistFieldSql TransactionData where
  sqlType _ = SqlOther "JSONB"

instance PersistField (M.Map String String) where
  toPersistValue = toPersistValueJSON
  fromPersistValue = fromPersistValueJSON

instance PersistFieldSql (M.Map String String) where
  sqlType _ = SqlOther "JSONB"

instance PersistField DeploymentStatus where
  toPersistValue = toPersistValueJSON
  fromPersistValue = fromPersistValueJSON

instance PersistFieldSql DeploymentStatus where
  sqlType _ = SqlString

instance PersistField DeployConfig where
  toPersistValue = toPersistValueJSON
  fromPersistValue = fromPersistValueJSON

instance PersistFieldSql DeployConfig where
  sqlType _ = SqlOther "JSONB"

instance PersistField [ConfigVM] where
  toPersistValue = toPersistValueJSON
  fromPersistValue (PersistByteString bs) = case (eitherDecode . BS.fromStrict) bs of
                                              (Left e)  -> (Left . T.pack) e
                                              (Right r) -> pure r
  fromPersistValue v = error (show v)

instance PersistFieldSql [ConfigVM] where
  sqlType _ = SqlOther "JSONB"

instance PersistField [Text] where
  toPersistValue = toPersistValueJSON
  fromPersistValue = fromPersistValueJSON

doMigration :: SqlPersistT IO ()
doMigration = runMigration migrateAll

runDB :: (MonadReader Config m, MonadIO m) => SqlPersistT IO b -> m b
runDB query = do
  pool <- asks configDBPool
  liftIO $ runSqlPool query pool
