{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Transaction 
  ( TransactionStage(..)
  , TransactionAction(..)
  , TransactionException(..)
  , TransactionM
  , TransactionState(..)
  , StatefulTransactionM
  , StatelessTransactionM
  ) where

import Api.Proxmox
import Data.Aeson
import Data.Models.Config.Network
import Data.Models.Config.VM
import Data.Models.Config.Template
import Api.Proxmox.Models.SDNNetwork
import Api.Proxmox.Models.VMClone
import Control.Monad.Trans.State
import Control.Monad.Trans.Except
import qualified Data.Map as M

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
  | DestroyVM Int
  | StopVM String
  | StartVM String
  | PauseSeconds Int
  deriving (Show, Eq)

data DeployTarget = Deploy | Destroy deriving Show

data TransactionException = BridgeNotFound String 
  | SDNZoneNotFound String 
  | TemplateNotFound ConfigTemplate 
  | NonTemplateLink ConfigTemplate 
  | UnknownError String deriving Show

data TransactionState = TransactionState 
  { transactionAllocateVMIDF :: () -> StatefulTransactionM Int
  , transactionActions :: ![TransactionAction]
  , transactionCompletedActions :: ![TransactionAction]
  , transactionVMIDMap :: M.Map String Int
  , transactionProxmoxState :: !ProxmoxState
  }

type StatelessTransactionM a = TransactionM IO a

type StatefulTransactionM a = TransactionM (StateT TransactionState IO) a

type TransactionM m a = ExceptT TransactionException m a
