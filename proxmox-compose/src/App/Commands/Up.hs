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
