module Api.Ssl (noSSLManager) where

import Network.Connection
import Network.HTTP.Conduit

noSSLManager :: IO Manager
noSSLManager = newManager $ mkManagerSettings tlsSettings Nothing where
  tlsSettings = TLSSettingsSimple
    { settingDisableCertificateValidation = True
    , settingDisableSession = False
    , settingUseServerName = True
    }
