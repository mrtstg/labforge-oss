module App.Commands.Down
  (runDownCommand) where

import           Api.Proxmox
import           App.Commands.Common
import           Control.Monad.Trans.Except
import           Control.Monad.Trans.State
import           Data.Models.Config
import           Data.Models.Config.Deploy
import           Data.Models.Transaction
import           Deploy.Transaction
import           Deploy.VM
import           System.Exit
import           System.Log.Logger
import           Utils

loggerName = "ProxmoxCompose.Main"

runDownCommand :: ProxmoxState -> DeployConfig -> FilePath -> IO ()
runDownCommand proxmoxState deployConfig configPath = do
  actions <- genericTransactionBuilder (defaultStatePathGenerator configPath) proxmoxState deployConfig Destroy
  () <- getTransactionAgreement
  let state' = defaultTransactionState (defaultStatePathGenerator configPath) actions proxmoxState deployConfig
  (res, _) <- runStateT (runExceptT executeTransaction) state'
  print res
  exitSuccess
