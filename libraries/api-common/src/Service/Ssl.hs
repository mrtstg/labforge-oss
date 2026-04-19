{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings  #-}
module Service.Ssl (
  createSSLManager
  ) where

import           Data.Maybe
import           Network.Connection
import           Network.HTTP.Conduit

createSSLManager :: Bool -> Maybe Int -> IO Manager
createSSLManager ignoreSSL timeout = let
  tlsSettings = TLSSettingsSimple
    { settingDisableCertificateValidation = ignoreSSL
    , settingDisableSession = False
    , settingUseServerName = True
    }

  in do
  let settings = mkManagerSettings tlsSettings Nothing
  newManager (settings { managerResponseTimeout = responseTimeoutMicro (fromMaybe 30_000_000 timeout) })
