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
  } | RawVM 
  { configVMName :: !String
  , configVMID :: !(Maybe Int)
  } deriving Show

instance FromJSON ConfigVM where
  parseJSON = withObject "ConfigVM" $ \v -> case KM.lookup "clone_from" v of
    Nothing -> RawVM 
      <$> v .: "name"
      <*> v .:? "vmid"
    (Just (String _)) -> TemplatedConfigVM
      <$> v .: "clone_from"
      <*> v .: "name"
      <*> v .:? "vmid"
    _anyOtherType -> fail "clone_from field has incorrect value type!"

isTemplateVM :: ConfigVM -> Bool
isTemplateVM (TemplatedConfigVM {}) = True
isTemplateVM _ = False
