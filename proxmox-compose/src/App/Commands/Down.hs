module App.Commands.Down
  (runDownCommand) where

import           App.Commands.Common
import           Control.Monad.Except
import           Control.Monad.State
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Transaction
import           Proxmox.Deploy.Transaction
import           Proxmox.Schema
import           System.Exit
import           System.Log.Logger

loggerName = "ProxmoxCompose.Main"

runDownCommand :: ProxmoxState -> DeployConfig -> FilePath -> IO ()
runDownCommand proxmoxState deployConfig configPath = do
  actions <- genericTransactionBuilder (defaultStatePathGenerator configPath) proxmoxState deployConfig Destroy
  () <- getTransactionAgreement
  let state' = defaultTransactionState Destroy (defaultStatePathGenerator configPath) actions proxmoxState deployConfig
  result <- (liftIO . runExceptT) $ runStateT (unTransaction executeTransaction) state'
  case result of
    (Left e) -> do
      errorM loggerName $ "Transaction error: " <> show e
    (Right _) -> do
      infoM loggerName "All finished!"
  exitSuccess
