module App.Commands.Up
  ( runUpCommand
  ) where

import           Api.Proxmox
import           App.Commands.Common
import           Control.Monad.Trans.Except
import           Control.Monad.Trans.State
import           Data.Models.Config
import           Data.Models.Transaction
import           Deploy.Transaction
import           System.Exit

loggerName = "ProxmoxCompose.Main"

runUpCommand :: ProxmoxState -> DeployConfig -> FilePath -> IO ()
runUpCommand proxmoxState deployConfig configPath = do
  actions <- genericTransactionBuilder (defaultStatePathGenerator configPath) proxmoxState deployConfig Deploy
  () <- getTransactionAgreement
  let state' = defaultTransactionState (defaultStatePathGenerator configPath) actions proxmoxState deployConfig
  (res, _) <- runStateT (runExceptT executeTransaction) state'
  print res
  exitSuccess
