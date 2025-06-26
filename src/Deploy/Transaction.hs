{-# LANGUAGE RecordWildCards #-}
module Deploy.Transaction 
  ( planTransactionStages
  , planTransactionActions
  ) where

import qualified Data.Text as T
import qualified Data.Map as M
import Api.Proxmox.Models.VM
import Data.Map (Map)
import Data.Models.Config.Deploy
import Api.Proxmox.Models.VMClone
import Data.Models.Config.VM
import Data.Models.Config.Network
import Api.Proxmox.Models.Network
import Api.Proxmox.Models.SDNNetwork
import Data.Models.Config.Template
import Data.Models.Config
import Data.Models.Transaction
import Api.Proxmox.Models.SDNZone
import Control.Monad.Trans.Writer
import Data.Functor.Identity
import Data.Functor ((<&>))
import Control.Monad.Trans.Except
import Data.Maybe

planTransactionStages :: DeployConfig -> [TransactionStage]
planTransactionStages (DeployConfig { deployVMs=vms, deployTemplates=templates, deployNetworks=networks}) = let
  f :: WriterT [TransactionStage] Identity ()
  f = do
    tell $ map TemplateExists templates
    tell $ map NetworkExists networks
    tell $ map VMExists vms
  in (snd . runIdentity . runWriterT) f

planTransactionActions :: [TransactionStage] -> DeployConfig -> [ProxmoxNetwork] -> [ProxmoxSDNZone] -> [ProxmoxSDNNetwork] -> Map Int ProxmoxVM -> Either TransactionException [TransactionAction]
planTransactionActions stages (DeployConfig { deployTemplates = vmTemplates, deployParameters = DeployParams { deployNodeName = deployNodeName } }) bridges sdnZones sdnNetworks vmMap = (runIdentity . runExceptT) $ helper stages []  where
  helper :: [TransactionStage] -> [TransactionAction] -> TransactionM Identity [TransactionAction]
  helper [] acc = (pure . reverse) acc
  helper ((NetworkExists (ExistingNetwork networkName)):ts) acc = if any ((==) networkName . proxmoxNetworkInterface) bridges then helper ts acc else
    throwE (BridgeNotFound networkName)
  helper ((NetworkExists SDNNetwork { .. }):ts) acc = do
    let sdnCreate = ProxmoxSDNNetworkCreate 
          { sdnNetworkCreateZone=configNetworkZone
          , sdnNetworkCreateVlanaware=Nothing
          , sdnNetworkCreateTag=Nothing
          , sdnNetworkCreateName=configNetworkName
          , sdnNetworkCreateAlias=Nothing
          }
    if all ((/=) configNetworkZone . proxmoxSDNZoneName) sdnZones then throwE (SDNZoneNotFound configNetworkZone) else
      if any (\x -> sdnNetworkName x == configNetworkName && sdnNetworkZone x == configNetworkZone) sdnNetworks then
        helper ts acc
      else
        helper ts (DeploySDNNetwork sdnCreate:acc)
  helper ((NetworkNotExists (ExistingNetwork {})):ts) acc = helper ts acc
  helper ((NetworkNotExists (SDNNetwork { .. })):ts) acc = do
    if all (\x -> sdnNetworkZone x /= configNetworkZone || sdnNetworkName x /= configNetworkName) sdnNetworks 
      then do
         let sdnCreate = ProxmoxSDNNetworkCreate
              { sdnNetworkCreateZone = configNetworkZone
              , sdnNetworkCreateName = configNetworkName
              , sdnNetworkCreateVlanaware=Nothing
              , sdnNetworkCreateTag=Nothing
              , sdnNetworkCreateAlias=Nothing
              }
         helper ts (DestroySDNNetwork sdnCreate:acc)
    else helper ts acc
  helper ((TemplateExists t@(ConfigTemplate { configTemplateID = tID })):ts) acc = do
    case M.lookup tID vmMap of
      Nothing -> throwE (TemplateNotFound t)
      (Just (ProxmoxVM { vmTemplate=True, vmLock=Nothing })) -> helper ts acc
      _vmInvalid -> throwE (NonTemplateLink t)
  helper ((VMExists vm@(RawVM { configVMID = vmID, configVMName = vmName, configVMDelay = delay })):ts) acc = case vmID of
    Nothing -> helper ts (PauseSeconds delay:StartVM vmName:CreateVM vm:AssignVMID vmName:acc)
    (Just _) -> helper ts (PauseSeconds delay:StartVM vmName:CreateVM vm:acc)
  helper ((VMExists (TemplatedConfigVM { configVMParentTemplate = parentTemplateName, configVMName = vmName, configVMID = vmID, configVMDelay = delay })):ts) acc = do
    case filter ((==) parentTemplateName . configTemplateName) vmTemplates of
      [] -> throwE (TemplateNotFound (ConfigTemplate {configTemplateName = parentTemplateName, configTemplateID = 0 }))
      (ConfigTemplate { configTemplateID = templateID }:_) -> do
        let cloneStage = CloneVM (ProxmoxVMCloneParams {getVMCloneVMID = templateID, getVMCloneStorage = Nothing, getVMCloneSnapname = Nothing, getVMCloneNode = deployNodeName, getVMCloneNewID = fromMaybe (-1) vmID, getVMCloneName = (Just . T.pack) vmName, getVMCloneDescription=Nothing})
        case vmID of
          Nothing -> helper ts (PauseSeconds delay:StartVM vmName:cloneStage:AssignVMID vmName:acc)
          (Just _) -> helper ts (PauseSeconds delay:StartVM vmName:cloneStage:acc)
  helper ((VMNotExists _):ts) acc = helper ts acc -- TODO: finish
--planTransactionStages :: [TransactionStage] -> 
--planTransaction :: DeployConfig -> [ProxmoxNetwork] -> [ProxmoxSDNNetwork] -> [DeployTransaction]
--planTransaction (DeployConfig { deployNetworks = nets }) existingNetworks sdnNetworks = let
--  nonVnetNames = map proxmoxNetworkInterface . filter ((/= Vnet) . proxmoxNetworkType) $ existingNetworks
--
--  f :: [DeployTransaction] -> [ConfigNetwork] -> [DeployTransaction]
--  f acc [] = acc
--  f acc (ExistingNetwork { configNetworkName = networkName }:ns) = case filter ((==networkName) . proxmoxNetworkInterface) existingNetworks of
--    [] -> f (FailWith (NetworkNotFound networkName):acc) ns
--    _ -> f acc ns
--  f acc (SDNNetwork {configNetworkName=name, configNetworkDisplayName=Nothing}:ns) =
--    f (FailWith (InternalError $ "SDN network " <> name <> "got no assigned display name"):acc) ns
--  f acc (SDNNetwork {configNetworkZone = zone, configNetworkName = name, configNetworkDisplayName = Just dname}:ns) = do
--    if dname `elem` nonVnetNames then f (FailWith (NetworkNameTaken dname):acc) ns else do
--      undefined
--  in do
--    undefined
