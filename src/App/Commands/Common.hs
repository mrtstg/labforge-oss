{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
module App.Commands.Common 
  ( getActiveNodesVMMap'
  , getBridges'
  , getSDNNetworks'
  , getSDNZones'
  , defaultTransactionState
  , defaultStatePathGenerator
  , genericTransactionBuilder
  , getTransactionAgreement
  ) where

import Api.Proxmox
import Api.Proxmox.Models.VM
import Api.Proxmox.Models.Network
import Data.Map (Map)
import Data.Text (Text)
import Api.Proxmox.Models
import Api.Proxmox.Models.SDNZone
import Api.Proxmox.Models.SDNNetwork
import Api.Proxmox.Client
import qualified Api.Proxmox.Client as C
import Control.Exception
import Api.Retry
import Deploy.Types
import Control.Monad.Trans.Class (lift)
import qualified Data.Map as M
import Control.Monad.IO.Class (liftIO)
import Data.Models.Config
import System.Directory
import Data.Aeson
import System.Log.Logger
import Utils
import Deploy.Transaction
import Data.Models.Transaction
import Control.Monad.Trans.Except
import Control.Monad.Trans.State
import System.FilePath
import System.Exit
import Deploy.VM
import Data.Models.Config.Deploy
import qualified Data.Text as T

loggerName = "ProxmoxCompose.Main"

getTransactionAgreement :: IO ()
getTransactionAgreement = do
  infoM loggerName "Are you agree to execute following actions? [yes/no]"
  userInput <- getLine
  case (T.toLower . T.pack) userInput of
    "yes" -> return ()
    "no" -> do
      infoM loggerName "Stopping program execution"
      exitSuccess
    _otherInput -> getTransactionAgreement

genericTransactionBuilder :: ProxmoxState -> DeployConfig -> DeployTarget -> IO [TransactionAction]
genericTransactionBuilder proxmoxState deployConfig@(DeployConfig 
    { deployParameters = DeployParams { deployNodeName = nodeName }
    , deployTemplates = templates
    , deployVMs = vms
    , deployNetworks = networks
    }) target = do
  () <- commonErrorStdoutHandler loggerName (pure $ validateVMsData templates vms) show
  vmMap <- getActiveNodesVMMap' proxmoxState
  bridges <- getBridges' proxmoxState nodeName
  sdnNetworks <- getSDNNetworks' proxmoxState
  sdnZones <- getSDNZones' proxmoxState

  infoM loggerName "Building transaction..."
  let stages = planTransactionStages deployConfig target
  let transactionRes = planTransactionActions stages deployConfig bridges sdnZones sdnNetworks vmMap
  case transactionRes of
    (Left e) -> do
      errorM loggerName ("Failed to build transaction: " <> show e)
      exitWith (ExitFailure 1)
    (Right []) -> do
      infoM loggerName "No actions needed!"
      exitSuccess
    (Right actions) -> do
      mapM_ print actions
      return actions

getActiveNodesVMMap' :: ProxmoxState -> IO (Map Int ProxmoxVM)
getActiveNodesVMMap' proxmoxState = do
  infoM loggerName "Retrieving node virtual machines info..."
  commonErrorStdoutHandler loggerName (defaultRetryClient' proxmoxState C.getActiveNodesVMMap) (\err -> "Failed to get node VMs: " <> displayException err)

getBridges' :: ProxmoxState -> Text -> IO [ProxmoxNetwork]
getBridges' proxmoxState nodeName = do
  infoM loggerName "Getting node bridges..."
  commonErrorStdoutHandler loggerName (defaultRetryClient' proxmoxState $ getBridgeNodeNetworks nodeName) (\e -> "Failed to get node bridges: " <> displayException e)

getSDNNetworks' :: ProxmoxState -> IO [ProxmoxSDNNetwork]
getSDNNetworks' proxmoxState = do
  (ProxmoxResponse networks) <- commonErrorStdoutHandler loggerName (defaultRetryClient' proxmoxState getSDNNetworks) (\e -> "Failed to get SDN networks: " <> displayException e)
  return networks

getSDNZones' :: ProxmoxState -> IO [ProxmoxSDNZone]
getSDNZones' proxmoxState = do
  (ProxmoxResponse zones) <- commonErrorStdoutHandler loggerName (defaultRetryClient' proxmoxState getSDNZones) (\e -> "Failed to get SDN zones: " <> displayException e)
  return zones

defaultStatePathGenerator :: FilePath -> FilePath
defaultStatePathGenerator configPath = do
  let (dir, filename) = splitFileName configPath
  let filename' = addExtension ("." <> dropExtensions filename <> "-state") "json"
  dir `combine` filename'

defaultTransactionState :: FilePath -> [TransactionAction] -> ProxmoxState -> DeployConfig -> TransactionState
defaultTransactionState statePath actions proxmoxState deployConfig = let

  allocateF :: StatefulTransactionM Int
  allocateF = do
    (TransactionState { transactionDeployConfig = (DeployConfig { deployParameters = DeployParams { deployStartVMID = startVMID } }), .. }) <- lift get
    (TransactionData vmMap) <- transactionDataGetF
    let vmIds = map snd $ M.toList vmMap
    nodeMap' <- liftIO $ defaultRetryClient' proxmoxState getActiveNodesVMMap
    case nodeMap' of
      (Left e) -> throwE (ClientError e)
      (Right nodeMap) -> do
        let nodeIds = map (vmID . snd) $ M.toList nodeMap
        (return . head) (getVMIDRange startVMID (vmIds ++ nodeIds))

  getF :: StatefulTransactionM TransactionData
  getF = do
    stateFileExists <- liftIO $ doesFileExist statePath
    if stateFileExists then do
      decodeRes <- liftIO $ eitherDecodeFileStrict statePath
      case decodeRes of
        (Left e) -> throwE (FileError e)
        (Right d@(TransactionData {})) -> pure d
    else do
      return (TransactionData M.empty)

  setF :: TransactionData -> StatefulTransactionM ()
  setF d = liftIO $ encodeFile statePath d
  in TransactionState 
    { transactionProxmoxState = proxmoxState
    , transactionDataSetF = setF
    , transactionDataGetF = getF
    , transactionAllocateVMIDF = allocateF
    , transactionActions = actions
    , transactionDeployConfig = deployConfig
    }
