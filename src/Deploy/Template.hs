module Deploy.Template (vmIDPresent) where

import Api.Proxmox.Models.VM
import qualified Data.Map as M

-- looks up is VMID present in VMs map, used for
-- checking, is templates existing
vmIDPresent :: M.Map Int ProxmoxVM -> [Int] -> Either [Int] ()
vmIDPresent vms = helper [] where
  helper :: [Int] -> [Int] -> Either [Int] ()
  helper [] [] = Right ()
  helper acc [] = Left acc
  helper acc (vmid:vmids) = do
    case M.lookup vmid vms of
      Nothing -> helper (vmid:acc) vmids
      _vmFound -> helper acc vmids
