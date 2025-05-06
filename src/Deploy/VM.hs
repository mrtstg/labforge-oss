{-# LANGUAGE RecordWildCards #-}
module Deploy.VM 
  ( vmTemplatesPresented
  , validateVMsData
  , VMValidateError(..)
  ) where

import Data.Models.Config.VM (ConfigVM(..))
import Data.Models.Config.Template
import Utils (returnFirstDuplicate)

type TemplateName = String
type VMName = String

data VMValidateError = TemplateIsNotPresent TemplateName | TemplateNameRepeat TemplateName | VMNameRepeat VMName

instance Show VMValidateError where
  show (TemplateIsNotPresent templateName) = "Template " <> show templateName <> " is not listed in config file"
  show (TemplateNameRepeat templateName) = "Template name " <> show templateName <> " is used two or more times"
  show (VMNameRepeat vmName) = "VM name " <> show vmName <> " is used two or more times"

validateVMsData :: [ConfigTemplate] -> [ConfigVM] -> Either VMValidateError ()
validateVMsData templates vms = do
  () <- vmTemplatesPresented templates vms
  () <- do
    case returnFirstDuplicate (map configTemplateName templates) of
      Nothing -> Right ()
      (Just el) -> (Left . TemplateNameRepeat) el
  () <- do
    case returnFirstDuplicate (map configVMName vms) of
      Nothing -> Right ()
      (Just el) -> (Left . VMNameRepeat) el
  return ()

-- checks, is templates presented on NAME level
-- existence in proxmox node checked earlier
vmTemplatesPresented :: [ConfigTemplate] -> [ConfigVM] -> Either VMValidateError ()
vmTemplatesPresented templates = let
  templatesNames = map configTemplateName templates
  helper :: [ConfigVM] -> Either VMValidateError ()
  helper [] = Right ()
  helper (RawVM {}:vms) = helper vms
  helper (TemplatedConfigVM { .. }:vms) = if configVMParentTemplate `notElem` templatesNames then (Left . TemplateIsNotPresent) configVMParentTemplate else helper vms
  in helper
