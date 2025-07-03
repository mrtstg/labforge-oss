module App.Commands.Down 
  (runDownCommand) where

import Deploy.VM
import Api.Proxmox
import System.Exit
import Data.Models.Config.Deploy
import Data.Models.Config
import System.Log.Logger
import Utils
import Deploy.Transaction
import App.Commands.Common
import Data.Models.Transaction
import Control.Monad.Trans.Except
import Control.Monad.Trans.State

loggerName = "ProxmoxCompose.Main"

runDownCommand :: ProxmoxState -> DeployConfig -> FilePath -> IO ()
runDownCommand proxmoxState deployConfig configPath = do
  actions <- genericTransactionBuilder proxmoxState deployConfig Destroy
  () <- getTransactionAgreement
  let state' = defaultTransactionState (defaultStatePathGenerator configPath) actions proxmoxState deployConfig
  (res, _) <- runStateT (runExceptT executeTransaction) state'
  print res
  exitSuccess
