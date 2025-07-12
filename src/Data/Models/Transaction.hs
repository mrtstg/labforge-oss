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
  , defaultTransactionDelayAfter
  , transactionActionPriority
  ) where

import           Api.Proxmox
import           Api.Proxmox.Models.SDNNetwork
import           Api.Proxmox.Models.VMClone
import           Control.Monad.Trans.Except
import           Control.Monad.Trans.State
import           Data.Models.Config
import           Data.Models.Config.Network
import           Data.Models.Config.Template
import           Data.Models.Config.VM
import           Deploy.Types
import           Servant.Client

data TransactionStage
  = NetworkExists ConfigNetwork
  | NetworkNotExists ConfigNetwork
  | VMExists ConfigVM
  | VMNotExists ConfigVM
  | TemplateExists ConfigTemplate
  | NetworkConnected String ConfigVMNetwork
  | NetworksRemoved String
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
  | RemoveNetworks String
  | AttachNetwork String ConfigVMNetwork
  | TransactionDelayAfter Int TransactionAction
  deriving (Show, Eq)

-- from -100 to 100, used for sorting actions
transactionActionPriority :: TransactionAction -> Int
transactionActionPriority (TransactionDelayAfter _ action) = transactionActionPriority action
transactionActionPriority (StartVM {}) = 50
transactionActionPriority _ = 0

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
  | VMIDTaken Int
  | NetworkIsNotDeclared String
  | VMConfigIsNotFound String deriving Show

defaultTransactionDelayAfter :: TransactionAction -> TransactionAction
defaultTransactionDelayAfter = TransactionDelayAfter 5

data TransactionState = TransactionState
  { transactionAllocateVMIDF :: StatefulTransactionM Int
  , transactionDataGetF      :: StatefulTransactionM TransactionData
  , transactionDataSetF      :: TransactionData -> StatefulTransactionM ()
  , transactionActions       :: ![TransactionAction]
  , transactionDeployConfig  :: !DeployConfig
  , transactionProxmoxState  :: !ProxmoxState
  }

type StatelessTransactionM a = TransactionM IO a

type StatefulTransactionM a = TransactionM (StateT TransactionState IO) a

type TransactionM m a = ExceptT TransactionException m a

defaultClientErrorWrapper :: Either ClientError a -> StatefulTransactionM a
defaultClientErrorWrapper (Left e)  = throwE (ClientError e)
defaultClientErrorWrapper (Right v) = pure v
