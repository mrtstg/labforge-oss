{-# LANGUAGE RecordWildCards #-}
module Deploy.VM 
  ( vmTemplatesPresented
  , validateVMsData
  , VMValidateError(..)
  ) where

import Data.Models.Config.VM (ConfigVM(..))
import Data.Models.Config.Template

type TemplateName = String

data VMValidateError = TemplateIsNotPresent TemplateName

instance Show VMValidateError where
  show (TemplateIsNotPresent templateName) = "Template " <> templateName <> " is not listed in config file"

validateVMsData :: [ConfigTemplate] -> [ConfigVM] -> Either VMValidateError ()
validateVMsData templates vms = do
  case vmTemplatesPresented templates vms of
    Left templateName -> Left (TemplateIsNotPresent templateName)
    Right _ -> return ()

vmTemplatesPresented :: [ConfigTemplate] -> [ConfigVM] -> Either String ()
vmTemplatesPresented templates = let
  templatesNames = map configTemplateName templates
  helper :: [ConfigVM] -> Either String ()
  helper [] = Right ()
  helper (RawVM {}:vms) = helper vms
  helper (TemplatedConfigVM { .. }:vms) = if configVMParentTemplate `notElem` templatesNames then Left configVMParentTemplate else helper vms
  in helper
