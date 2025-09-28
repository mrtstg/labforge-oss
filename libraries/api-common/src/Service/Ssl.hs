{-# LANGUAGE OverloadedStrings #-}
module Service.Ssl (
  createSSLManager
  ) where

import           Network.Connection
import           Network.HTTP.Conduit

createSSLManager :: Bool -> IO Manager
createSSLManager ignoreSSL = let
  tlsSettings = TLSSettingsSimple
    { settingDisableCertificateValidation = ignoreSSL
    , settingDisableSession = False
    , settingUseServerName = True
    }

  in do
  let settings = mkManagerSettings tlsSettings Nothing
  newManager settings
