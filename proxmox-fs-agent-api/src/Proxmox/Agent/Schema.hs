{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeOperators     #-}
module Proxmox.Agent.Schema
  ( AgentAPI
  ) where

import           Data.Aeson
import qualified Data.ByteString.Char8 as BS
import           Data.Text
import           Servant.API

newtype AgentToken = AgentToken Text deriving (Show, Eq)

instance ToHttpApiData AgentToken where
  toHeader (AgentToken token) = (BS.pack . unpack) $ "Bearer " <> token

data VNCRequest = VNCRequest
  { reqDisplay :: !Int
  , reqNetwork :: !Text
  } deriving Show

instance ToJSON VNCRequest  where
  toJSON (VNCRequest { .. }) = object
    [ "display" .= reqDisplay
    , "network" .= reqNetwork
    ]

instance FromJSON VNCRequest where
  parseJSON = withObject "VNCRequest" $ \v -> VNCRequest <$> v .: "display" <*> v .:? "network" .!= "0.0.0.0"

type AgentAPI = "args" :> "vnc" :> Capture "vmid" Int :> ReqBody '[JSON] VNCRequest :> Post '[JSON] ()
