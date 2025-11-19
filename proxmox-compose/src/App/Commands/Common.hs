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
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module App.Commands.Common
  ( getActiveNodesVMMap'
  , getBridges'
  , getSDNNetworks'
  , getSDNZones'
  , defaultTransactionState
  , defaultStatePathGenerator
  , genericTransactionBuilder
  , getTransactionAgreement
  , defaultROTransactionState
  , transitionLogF
  ) where

import           Control.Exception
import           Control.Monad.Except
import           Control.Monad.IO.Class              (liftIO)
import           Control.Monad.Logger
import           Control.Monad.State
import           Data.Aeson
import qualified Data.ByteString.Char8               as BS
import           Data.Map                            (Map)
import qualified Data.Map                            as M
import           Data.Text                           (Text)
import qualified Data.Text                           as T
import           Proxmox.Client
import qualified Proxmox.Client                      as C
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.Deploy
import           Proxmox.Deploy.Models.Transaction
import           Proxmox.Deploy.Transaction
import           Proxmox.Deploy.Types
import           Proxmox.Deploy.VM
import           Proxmox.Models
import           Proxmox.Models.Network
import           Proxmox.Models.SDNNetwork
import           Proxmox.Models.SDNZone
import           Proxmox.Models.Storage
import           Proxmox.Models.VM
import           Proxmox.Retry
import           Proxmox.Schema
import           System.Directory
import           System.Exit
import           System.FilePath
import           System.Log.Logger
import           Utils

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

genericTransactionBuilder :: FilePath -> ProxmoxState -> DeployConfig -> DeployTarget -> IO [TransactionAction]
genericTransactionBuilder statePath proxmoxState deployConfig@(DeployConfig
    { deployParameters = DeployParams { deployNodeName = nodeName }
    , deployTemplates = templates
    , deployVMs = vms
    , deployNetworks = networks
    }) target = do
  debugM loggerName $ "Parsed config: " <> show deployConfig
  () <- flip runLoggingT transitionLogF $ commonErrorStdoutHandler' (pure $ validateVMsData templates vms)
  vmMap <- getActiveNodesVMMap' proxmoxState
  bridges <- getBridges' proxmoxState nodeName
  sdnNetworks <- getSDNNetworks' proxmoxState
  sdnZones <- getSDNZones' proxmoxState
  storages <- getNodeStorage' proxmoxState nodeName

  infoM loggerName "Building transaction..."
  let stages = planTransactionStages deployConfig target
  debugM loggerName $ "First stages: " <> show stages
  transactionRes <- planTransactionActions stages bridges sdnZones sdnNetworks storages vmMap (defaultROTransactionState target statePath proxmoxState deployConfig)
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

getNodeStorage' :: ProxmoxState -> Text -> IO [ProxmoxStorage]
getNodeStorage' proxmoxState nodeName = do
  infoM loggerName "Getting target node storages..."
  flip runLoggingT transitionLogF $ commonErrorStdoutHandler (defaultRetryClient' proxmoxState $ C.getNodeStorage nodeName (ProxmoxStorageFilter { storageTarget = Just nodeName, storageEnabled = Just True })) (\err -> T.pack $ "Failed to get node VMs: " <> displayException err)

getActiveNodesVMMap' :: ProxmoxState -> IO (Map Int ProxmoxVM)
getActiveNodesVMMap' proxmoxState = do
  infoM loggerName "Retrieving node virtual machines info..."
  flip runLoggingT transitionLogF $ commonErrorStdoutHandler (defaultRetryClient' proxmoxState C.getActiveNodesVMMap) (\err -> T.pack $ "Failed to get node VMs: " <> displayException err)

getBridges' :: ProxmoxState -> Text -> IO [ProxmoxNetwork]
getBridges' proxmoxState nodeName = do
  infoM loggerName "Getting node bridges..."
  flip runLoggingT transitionLogF $ commonErrorStdoutHandler (defaultRetryClient' proxmoxState $ getBridgeNodeNetworks nodeName) (\e -> T.pack $ "Failed to get node bridges: " <> displayException e)

getSDNNetworks' :: ProxmoxState -> IO [ProxmoxSDNNetwork]
getSDNNetworks' proxmoxState = do
  (ProxmoxResponse { proxmoxData = networks }) <- flip runLoggingT transitionLogF $ commonErrorStdoutHandler (defaultRetryClient' proxmoxState $ getSDNNetworks Nothing) (\e -> T.pack $ "Failed to get SDN networks: " <> displayException e)
  return networks

getSDNZones' :: ProxmoxState -> IO [ProxmoxSDNZone]
getSDNZones' proxmoxState = do
  (ProxmoxResponse { proxmoxData = zones }) <- flip runLoggingT transitionLogF $ commonErrorStdoutHandler (defaultRetryClient' proxmoxState getSDNZones) (\e -> T.pack $ "Failed to get SDN zones: " <> displayException e)
  return zones

defaultStatePathGenerator :: FilePath -> FilePath
defaultStatePathGenerator configPath = do
  let (dir, filename) = splitFileName configPath
  let filename' = addExtension ("." <> dropExtensions filename <> "-state") "json"
  dir `combine` filename'

defaultGetTrancactionF :: FilePath -> StatefulTransactionT TransactionData
defaultGetTrancactionF statePath = do
  stateFileExists <- liftIO $ doesFileExist statePath
  if stateFileExists then do
    decodeRes <- liftIO $ eitherDecodeFileStrict statePath
    case decodeRes of
      (Left e)                       -> throwError (FileError e)
      (Right d@(TransactionData {})) -> pure d
  else do
    return (TransactionData M.empty)

transitionLogF :: Loc -> LogSource -> LogLevel -> LogStr -> IO ()
transitionLogF _ _ l msg = do
  let strMsg = (BS.unpack . fromLogStr) msg
  case l of
    LevelInfo      -> infoM loggerName strMsg
    LevelError     -> errorM loggerName strMsg
    LevelWarn      -> warningM loggerName strMsg
    LevelDebug     -> debugM loggerName strMsg
    (LevelOther _) -> pure ()

defaultROTransactionState :: DeployTarget -> FilePath -> ProxmoxState -> DeployConfig -> TransactionState
defaultROTransactionState target statePath proxmoxState deployConfig =
  TransactionState
    { transactionProxmoxState = proxmoxState
    , transactionDataSetF = \_ -> pure ()
    , transactionDataGetF = defaultGetTrancactionF statePath
    , transactionAllocateVMIDF = pure 0
    , transactionActions = []
    , transactionDeployConfig = deployConfig
    , transactionTarget = target
    , transactionLogFunction = transitionLogF
    }

defaultTransactionState :: DeployTarget -> FilePath -> [TransactionAction] -> ProxmoxState -> DeployConfig -> TransactionState
defaultTransactionState target statePath actions proxmoxState deployConfig = let

  allocateF :: StatefulTransactionT Int
  allocateF = do
    (TransactionState { transactionDeployConfig = (DeployConfig { deployParameters = DeployParams { deployStartVMID = startVMID } }), .. }) <- get
    (TransactionData vmMap) <- transactionDataGetF
    let vmIds = map snd $ M.toList vmMap
    nodeMap' <- defaultRetryClient' proxmoxState getActiveNodesVMMap
    case nodeMap' of
      (Left e) -> throwError (ClientError e)
      (Right nodeMap) -> do
        let nodeIds = map (vmID . snd) $ M.toList nodeMap
        (return . head) (getVMIDRange startVMID (vmIds ++ nodeIds))

  setF :: TransactionData -> StatefulTransactionT ()
  setF d = liftIO $ encodeFile statePath d
  in TransactionState
    { transactionProxmoxState = proxmoxState
    , transactionDataSetF = setF
    , transactionDataGetF = defaultGetTrancactionF statePath
    , transactionAllocateVMIDF = allocateF
    , transactionActions = actions
    , transactionDeployConfig = deployConfig
    , transactionTarget = target
    , transactionLogFunction = transitionLogF
    }
