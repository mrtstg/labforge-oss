module Deploy.Network 
  ( validateConfigNetworks
  , NetworkValidateError(..)
  ) where

import Data.Models.Config.Network
import Api.Proxmox.Models.Network

type NetworkName = String

data NetworkValidateError = ExistingNetworkNotFound NetworkName

instance Show NetworkValidateError where
  show (ExistingNetworkNotFound network) = "Network " <> network <> " not found on node."

validateExistingNetworks :: [ConfigNetwork] -> [ProxmoxNetwork] -> Either NetworkValidateError ()
validateExistingNetworks configNetworks existingNetworks = let
  f :: ConfigNetwork -> Bool
  f ExistingNetwork {} = True
  f _ = False

  existingNetworksNames = map proxmoxNetworkInterface existingNetworks

  helper :: [ConfigNetwork] -> Either NetworkValidateError ()
  helper [] = return ()
  helper (ExistingNetwork { configNetworkName = networkName }:ns) = if networkName `notElem` existingNetworksNames then (Left . ExistingNetworkNotFound) networkName else helper ns
  helper (_:ns) = helper ns
  in do
    let networkToExist = filter f configNetworks
    helper networkToExist

validateConfigNetworks :: [ConfigNetwork] -> [ProxmoxNetwork] -> Either NetworkValidateError ()
validateConfigNetworks configNetworks existingNetworks = do
  () <- validateExistingNetworks configNetworks existingNetworks
  return ()
