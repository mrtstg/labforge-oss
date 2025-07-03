{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Transaction 
  ( TransactionStage(..)
  , TransactionAction(..)
  , TransactionException(..)
  , TransactionM
  , TransactionState(..)
  , StatefulTransactionM
  , StatelessTransactionM
  , DeployTarget(..)
  , defaultClientErrorWrapper
  ) where

import Api.Proxmox
import Data.Models.Config.Network
import Data.Models.Config.VM
import Data.Models.Config.Template
import Api.Proxmox.Models.SDNNetwork
import Api.Proxmox.Models.VMClone
import Control.Monad.Trans.State
import Control.Monad.Trans.Except
import Deploy.Types
import Servant.Client
import Data.Models.Config

data TransactionStage 
  = NetworkExists ConfigNetwork
  | NetworkNotExists ConfigNetwork
  | VMExists ConfigVM
  | VMNotExists ConfigVM
  | TemplateExists ConfigTemplate
  deriving (Show, Eq)

data TransactionAction 
  = DeploySDNNetwork ProxmoxSDNNetworkCreate 
  | DestroySDNNetwork ProxmoxSDNNetworkCreate
  | UnassignVMID String
  | AssignVMID String
  | CloneVM ProxmoxVMCloneParams
  | CreateVM ConfigVM -- replace
  | DestroyVM String
  | StopVM String
  | StartVM String
  | PauseSeconds Int
  deriving (Show, Eq)

data DeployTarget = Deploy | Destroy deriving (Show, Eq)

data TransactionException = BridgeNotFound String 
  | SDNZoneNotFound String
  | SDNVnetNotFound String
  | SDNVnetDeleteError String
  | TemplateNotFound ConfigTemplate
  | TemplateNodeNotFound ConfigTemplate
  | NonTemplateLink ConfigTemplate
  | FileError String
  | ClientError ClientError
  | MachineHasNoID String
  | VMDeleteError Int
  | VMLocked Int
  | UnknownError String
  | VMIDTaken Int deriving Show

data TransactionState = TransactionState 
  { transactionAllocateVMIDF :: StatefulTransactionM Int
  , transactionDataGetF :: StatefulTransactionM TransactionData
  , transactionDataSetF :: TransactionData -> StatefulTransactionM ()
  , transactionActions :: ![TransactionAction]
  , transactionDeployConfig :: !DeployConfig
  , transactionProxmoxState :: !ProxmoxState
  }

type StatelessTransactionM a = TransactionM IO a

type StatefulTransactionM a = TransactionM (StateT TransactionState IO) a

type TransactionM m a = ExceptT TransactionException m a

defaultClientErrorWrapper :: Either ClientError a -> StatefulTransactionM a
defaultClientErrorWrapper (Left e) = throwE (ClientError e)
defaultClientErrorWrapper (Right v) = pure v
