{-# LANGUAGE OverloadedStrings #-}
module Api.Ssl (createProxmoxManager) where

import Data.Text (unpack)
import Data.CaseInsensitive
import Network.Connection
import Network.HTTP.Client
import Network.HTTP.Conduit
import Data.Models.Config
import Data.Models.Config.Deploy
import qualified Data.ByteString.Char8 as BS

createProxmoxManager :: DeployConfig -> IO Manager
createProxmoxManager (DeployConfig { deployParameters=DeployParams {deployToken=token, deployIgnoreSSL=ignoreSSL}}) = let
  f :: Request -> IO Request
  f r = do
    case token of
      Nothing -> return r
      (Just tokenValue) -> do
        return (r { requestHeaders = filter ((/= "Authorization") . fst) (requestHeaders r) ++ [(mk $ BS.pack "Authorization", BS.pack $ "PVEAPIToken=" <> unpack tokenValue)]})

  tlsSettings = TLSSettingsSimple
    { settingDisableCertificateValidation = ignoreSSL
    , settingDisableSession = False
    , settingUseServerName = True
    }

  in do
  let settings = mkManagerSettings tlsSettings Nothing
  newManager (settings { managerModifyRequest = f })
