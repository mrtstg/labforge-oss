{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
module Data.Models.Transaction
  ( TransactionStage(..)
  , TransactionAction(..)
  , TransactionException(..)
  , TransactionState(..)
  , StatefulTransactionT(..)
  , DeployTarget(..)
  , defaultClientErrorWrapper
  , defaultTransactionDelayAfter
  ) where

import           Control.Monad.Except        (MonadError, throwError)
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.State         (MonadState)
import           Control.Monad.Trans.Except
import           Control.Monad.Trans.State
import           Data.Models.Config
import           Data.Models.Config.Network
import           Data.Models.Config.Template
import           Data.Models.Config.VM
import           Deploy.Types
import           Proxmox.Models.SDNNetwork
import           Proxmox.Models.VMClone
import           Proxmox.Schema
import           Servant.Client

data TransactionStage
  = NetworkExists ConfigNetwork
  | NetworkNotExists ConfigNetwork
  | VMExists ConfigVM
  | VMNotExists ConfigVM
  | TemplateExists ConfigTemplate
  | NetworkConnected String ConfigVMNetwork
  | NetworksRemoved String
  | VMStopped ConfigVM
  | VMRunning ConfigVM
  deriving (Show, Eq)

data TransactionAction
  = DeploySDNNetwork ProxmoxSDNNetworkCreate
  | DestroySDNNetwork ProxmoxSDNNetworkCreate
  | UnassignVMID String
  | AssignVMID String
  | CloneVM ProxmoxVMCloneParams
  | SetVMDisplay String Int
  | CreateVM ConfigVM -- replace
  | DestroyVM String
  | StopVM String
  | StartVM String
  | RemoveNetworks String
  | AttachNetwork String ConfigVMNetwork
  | TransactionDelayAfter Int TransactionAction
  | DetachNetwork String Int
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
  | VMIDTaken Int
  | NetworkIsNotDeclared String
  | VMConfigIsNotFound String
  | StorageNotFound String deriving Show

defaultTransactionDelayAfter :: TransactionAction -> TransactionAction
defaultTransactionDelayAfter = TransactionDelayAfter 5

data TransactionState = TransactionState
  { transactionAllocateVMIDF :: StatefulTransactionT Int
  , transactionDataGetF      :: StatefulTransactionT TransactionData
  , transactionDataSetF      :: TransactionData -> StatefulTransactionT ()
  , transactionActions       :: ![TransactionAction]
  , transactionDeployConfig  :: !DeployConfig
  , transactionProxmoxState  :: !ProxmoxState
  , transactionTarget        :: !DeployTarget
  }

newtype StatefulTransactionT a = StatefulTransactionT { unTransaction :: ExceptT TransactionException (StateT TransactionState (LoggingT IO)) a }
  deriving (Functor, Applicative, Monad, MonadIO, MonadState TransactionState, MonadError TransactionException)

defaultClientErrorWrapper :: Either ClientError a -> StatefulTransactionT a
defaultClientErrorWrapper (Left e)  = throwError (ClientError e)
defaultClientErrorWrapper (Right v) = pure v
