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
{-# LANGUAGE TemplateHaskell   #-}
module Utils where

import           Data.Map   (Map)
import qualified Data.Map   as M
import           Data.Maybe

leaveLastItem :: (Eq a) => a -> [a] -> [a]
leaveLastItem item = helper [] where
  helper acc [] = reverse acc
  helper acc (el:ls) = if el == item && hasItem item ls then helper acc ls else helper (el:acc) ls

hasItem :: (Eq a) => a -> [a] -> Bool
hasItem item = foldr (\ el -> (||) (item == el)) False

matchSnapshotRequirements :: String -> Bool
matchSnapshotRequirements "" = False
matchSnapshotRequirements s | length s > 30 = False
                            | length s < 3 = False
                            | otherwise = case s of
  ('_':_) -> False
  (fC:otherSyms) -> fC `elem` ['a'..'z'] ++ ['A'..'Z'] && all (`elem` ['a'..'z'] ++ ['A'..'Z'] ++ ['0'..'9'] ++ ['_']) otherSyms

suggestNetworkBridges :: [Map String String] -> M.Map String String -> Map String String
suggestNetworkBridges l namesMap = helper M.empty l where
  helper :: Map String String -> [Map String String] -> Map String String
  helper acc [] = acc
  helper acc (device:devices) = do
    case M.lookup "bridge" device of
      Nothing -> helper acc devices
      (Just bridgeValue) -> do
        let newBridge = fromMaybe bridgeValue (M.lookup bridgeValue namesMap)
        case filter (\v -> v /= bridgeValue && (length . filter (== ':')) v >= 5) (map snd (M.toList device)) of
          []      -> helper acc devices
          (mac:_) -> helper (M.insert mac newBridge acc) devices

--findVMByPort :: Text -> AppT (Maybe (ConfigVM, DeploymentInstanceData))
--findVMByPort port = do
--  related <- findInstanceByVMPort port
--  pure $ fmap (\(Entity _ instanceData, vm) -> (vm, instanceData)) related

iterLetters :: Int -> [String]
iterLetters 1 = map (:[]) ['a'..'z']
iterLetters n = do
  s <- iterLetters 1
  v <- iterLetters (n - 1)
  pure $ s <> v
