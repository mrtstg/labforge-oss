module Deploy 
  ( substituteProxmoxToken
  ) where

import Data.Models.Config.Deploy
import Data.Models.Config
import Data.Text (Text)
import qualified Data.Text as T
import Servant.Client

substituteProxmoxToken :: DeployConfig -> (Maybe Text -> ClientM a) -> ClientM a
substituteProxmoxToken (DeployConfig { deployParameters = DeployParams { deployToken = token' } }) m = case token' of
  (Just token) -> (m . Just) $ T.pack "PVEAPIToken=" <> token
  Nothing -> m Nothing
