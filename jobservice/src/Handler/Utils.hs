module Handler.Utils
  ( setDeploymentInstanceStatus
  , unpackError
  ) where

import           Api.Keycloak.Models
import           Api.Keycloak.Token
import           Api.Retry
import           Config
import           Control.Monad.Reader
import           Data.Text                    (Text)
import           Deployment.Client
import           Deployment.Models.Deployment
import           Servant.Client
import           Service.Environment

unpackError :: Either String (Either ClientError a) -> (String -> AppT (Maybe a)) -> AppT (Maybe a)
unpackError (Left tokenError) handler          = handler tokenError
unpackError (Right (Left clientError)) handler = handler . show $ clientError
unpackError (Right (Right res)) _              = (pure . pure) res

setDeploymentInstanceStatus :: Text -> DeploymentStatus -> AppT (Either String ())
setDeploymentInstanceStatus dId status = do
  deploymentEnv <- asks $ getEnvFor DeploymentService
  res <- withTokenVariable $ \token -> do
    defaultRetryClientC deploymentEnv (patchDeploymentInstance dId
      (DeploymentPatch {patchInstanceVMLinks=Nothing, patchInstanceState=Just status, patchInstanceNetworkMap=Nothing, patchInstanceDeployConfig=Nothing}) (BearerWrapper token))
  case res of
    (Left tokenError)          -> pure $ Left tokenError
    (Right (Left clientError)) -> (pure . Left . show) clientError
    (Right (Right ()))         -> (pure . pure) ()
