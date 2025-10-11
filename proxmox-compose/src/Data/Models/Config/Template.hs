{-# LANGUAGE OverloadedStrings #-}
module Data.Models.Config.Template (ConfigTemplate(..)) where

import Data.Aeson

data ConfigTemplate = ConfigTemplate 
  { configTemplateName :: !String
  , configTemplateID :: !Int
  } deriving (Show, Eq)

instance FromJSON ConfigTemplate where
  parseJSON = withObject "ConfigTemplate" $ \v -> ConfigTemplate
    <$> v .: "name"
    <*> v .: "id"
