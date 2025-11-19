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
module App.Commands.Up
  ( runUpCommand
  ) where

import           App.Commands.Common
import           Control.Monad.IO.Class
import           Control.Monad.Trans.Except
import           Control.Monad.Trans.State
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Transaction
import           Proxmox.Deploy.Transaction
import           Proxmox.Schema
import           System.Exit
import           System.Log.Logger

loggerName = "ProxmoxCompose.Main"

runUpCommand :: ProxmoxState -> DeployConfig -> FilePath -> IO ()
runUpCommand proxmoxState deployConfig configPath = do
  actions <- genericTransactionBuilder (defaultStatePathGenerator configPath) proxmoxState deployConfig Deploy
  () <- getTransactionAgreement
  let state' = defaultTransactionState Deploy (defaultStatePathGenerator configPath) actions proxmoxState deployConfig
  result <- (liftIO . runExceptT) $ runStateT (unTransaction executeTransaction) state'
  case result of
    (Left e) -> do
      errorM loggerName $ "Transaction error: " <> show e
    (Right _) -> do
      infoM loggerName "All finished!"
  exitSuccess
