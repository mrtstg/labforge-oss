{-# LANGUAGE OverloadedStrings #-}
module Proxmox.Models.VMConfig
  ( ProxmoxVMConfig(..)
  , vmConfigNetworkNumbers
  , vmNetworkDevices
  , vmNetworkBridges
  ) where

import           Data.Aeson
import           Data.Aeson.Key    (toString)
import qualified Data.Aeson.KeyMap as KM
import           Data.Bifunctor
import           Data.Function     ((&))
import qualified Data.Map          as M
import           Data.Maybe
import           Data.Text         (Text, isPrefixOf, pack, replace, unpack)
import           Parsers.Network
import           Text.Read         (readMaybe)

-- detailed configuration, like in /nodes/{node}/qemu/{vmid}/config
data ProxmoxVMConfig = ProxmoxVMConfig
  { vmDigest    :: !String
  , vmName      :: !(Maybe String)
  , vmTemplate  :: !Bool
  , vmLock      :: !(Maybe String)
  , vmConfigMap :: !(M.Map String Value)
  } deriving (Show, Eq, Ord)

instance FromJSON ProxmoxVMConfig where
  parseJSON = withObject "ProxmoxVMConfig" $ \v -> ProxmoxVMConfig
    <$> v .: "digest"
    <*> v .:? "name"
    <*> templateParser (KM.lookup "template" v)
    <*> v .:? "lock"
    <*> (pure . M.mapKeys toString . KM.toMap) v where
      templateParser Nothing             = pure False
      templateParser (Just (Number 1))   = pure True
      templateParser (Just (String "1")) = pure True
      templateParser _                   = pure False

vmConfigNetworkNumbers :: ProxmoxVMConfig -> [Int]
vmConfigNetworkNumbers (ProxmoxVMConfig { vmConfigMap = cfgMap }) =
  M.keys cfgMap & map pack & filter ("net" `isPrefixOf`) & map (replace "net" "") & mapMaybe (readMaybe . unpack)

vmNetworkDevices :: ProxmoxVMConfig -> M.Map Int (M.Map String String)
vmNetworkDevices cfg@(ProxmoxVMConfig { vmConfigMap = cfgMap }) = helper M.empty networkNumbers where
  networkNumbers = vmConfigNetworkNumbers cfg

  helper :: M.Map Int (M.Map String String) -> [Int] -> M.Map Int (M.Map String String)
  helper acc [] = acc
  helper acc (num:nums) = do
    case M.lookup ("net" <> show num) cfgMap of
      (Just (String networkString)) -> case parseNetworkDevice networkString of
        (Left _)          -> helper acc nums
        (Right valuesMap) -> helper (M.insert num valuesMap acc) nums
      _otherValues -> helper acc nums

vmNetworkBridges :: ProxmoxVMConfig -> M.Map Int String
vmNetworkBridges cfg = vmNetworkDevices cfg & M.toList & filter (isJust . M.lookup "bridge" . snd) & map (second (fromJust . M.lookup "bridge")) & M.fromList
