{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Config.VM 
  ( ConfigVM(..)
  , isTemplateVM
  ) where

import Data.Aeson
import qualified Data.Aeson.KeyMap as KM

data ConfigVM = TemplatedConfigVM 
  { configVMParentTemplate :: !String
  , configVMName :: !String
  , configVMID :: !(Maybe Int)
  , configVMDelay :: !Int
  } | RawVM 
  { configVMName :: !String
  , configVMID :: !(Maybe Int)
  , configVMDelay :: !Int
  } deriving (Show, Eq)

instance FromJSON ConfigVM where
  parseJSON = withObject "ConfigVM" $ \v -> case KM.lookup "clone_from" v of
    Nothing -> RawVM 
      <$> v .: "name"
      <*> v .:? "vmid"
      <*> v .:? "delay" .!= 0
    (Just (String _)) -> TemplatedConfigVM
      <$> v .: "clone_from"
      <*> v .: "name"
      <*> v .:? "vmid"
      <*> v .:? "delay" .!= 0
    _anyOtherType -> fail "clone_from field has incorrect value type!"

isTemplateVM :: ConfigVM -> Bool
isTemplateVM (TemplatedConfigVM {}) = True
isTemplateVM _ = False
