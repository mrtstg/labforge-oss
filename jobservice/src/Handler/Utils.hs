{- Copyright (C) 2025 Ilya Zamaratskikh

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, see <http://www.gnu.org/licenses>. -}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
module Handler.Utils
  ( setDeploymentInstanceStatus
  , unpackError
  , sendLogRequest
  , deployTransaction
  , processMask
  , createMaskFunction
  ) where

import           Api.BaseUrl
import           Api.Keycloak.Models
import           Api.Keycloak.Token
import           Api.Retry
import           Config
import           Control.Monad.Except
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Control.Monad.State
import qualified Data.ByteString.Char8                    as BS
import qualified Data.Map                                 as M
import           Data.Maybe
import           Data.Text                                (Text)
import qualified Data.Text                                as T
import           Deployment.Client
import qualified Deployment.Client                        as D
import           Deployment.Models.Deployment
import           Jobservice.Models
import           Notification.Client
import           Notification.Models
import qualified Proxmox.Client                           as P
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.Deploy
import           Proxmox.Deploy.Models.Config.DeployAgent
import           Proxmox.Deploy.Models.Config.Network
import           Proxmox.Deploy.Models.Config.Template
import           Proxmox.Deploy.Models.Config.VM
import           Proxmox.Deploy.Models.Transaction
import           Proxmox.Deploy.Ssl
import           Proxmox.Deploy.Transaction
import           Proxmox.Deploy.Types
import           Proxmox.Models
import           Proxmox.Models.Snapshot
import           Proxmox.Models.Storage
import           Proxmox.Schema
import           Servant.Client
import           Service.Environment
import           Utils.Time

createMaskFunction :: [Text] -> Text -> (ConfigVM -> Bool)
createMaskFunction vmNames mask = flip elem maskList . T.pack . configVMName where
  maskList = processMask vmNames mask

processMask :: [Text] -> Text -> [Text]
processMask vmNames "" = vmNames
processMask vmNames "*" = vmNames
processMask vmNames mask = do
  let maskParts = T.splitOn " " mask
  let negativeFilters = filter (\v -> T.isPrefixOf "!" v && v `notElem` vmNames) maskParts
  let hasNegativeFilters = not . null $ negativeFilters
  if hasNegativeFilters then do
    let negativeNames = map T.tail negativeFilters
    filter (`notElem` negativeNames) vmNames
  else filter (`elem` maskParts) vmNames

unpackError :: Either String (Either ClientError a) -> (String -> AppT (Maybe a)) -> AppT (Maybe a)
unpackError (Left tokenError) handler          = handler tokenError
unpackError (Right (Left clientError)) handler = handler . show $ clientError
unpackError (Right (Right res)) _              = (pure . pure) res

deployTransaction :: [TransactionStage] -> Text -> DeployConfig -> AppT Bool
deployTransaction stages deploymentKey deployConfig@(DeployConfig { deployParameters = DeployParams {deployUrl=deployUrl, deployNodeName=nodeName} }) = do
  cfg <- ask
  parseRes <- liftIO $ tryParseUrl (T.unpack deployUrl)
  case parseRes of
    (Left e) -> do
      $(logError) $ "Failed to parse URL: " <> T.pack e
      --addLogToDeploymentInstance deploymentKey $ "Failed to parse URL: " <> pack e
      --setDeploymentInstanceStatus deploymentKey Failed
      pure False
    (Right url) -> do
      m <- liftIO $ createProxmoxManager deployConfig
      let state = ProxmoxState url m
      let planState = TransactionState { transactionTarget=Deploy
        , transactionProxmoxState=state
        , transactionLogFunction=sendLogRequest deploymentKey cfg
        , transactionDeployConfig=deployConfig
        , transactionDataSetF=(\_ -> pure ())
        , transactionDataGetF=pure (TransactionData M.empty)
        , transactionAllocateVMIDF=throwError (UnknownError "Cant allocate VMID")
        , transactionActions=[]
        }
      v <- liftIO $ runProxmoxClient' state $ do
        a <- P.getBridgeNodeNetworks nodeName
        (ProxmoxResponse b _) <- P.getSDNZones
        (ProxmoxResponse c _) <- P.getSDNNetworks Nothing
        d <- P.getNodeStorage nodeName defaultProxmoxStorageFilter
        e <- P.getActiveNodesVMMap
        pure (a, b, c, d, e)
      case v of
        (Left e) -> do
          $(logError) $ "Failed to get PVE data: " <> (T.pack . show) e
          --addLogToDeploymentInstance deploymentKey $ "Failed to get PVE data: " <> (pack . show) e
          --setDeploymentInstanceStatus deploymentKey Failed
          pure False
        (Right (a, b, c, d, e)) -> do
          planRes <- liftIO $ planTransactionActions stages a b c d e planState
          case planRes of
            (Left e) -> do
              $(logError) $ "Failed to plan transaction: " <> (T.pack . show) e
              --addLogToDeploymentInstance deploymentKey $ "Failed to plan transaction: " <> (pack . show) e
              --setDeploymentInstanceStatus deploymentKey Failed
              pure False
            (Right actions) -> do
              $(logDebug) $ "Generated actions: " <> (T.pack . show) actions
              result <- (liftIO . runExceptT) $ (runStateT (unTransaction executeTransaction) (planState { transactionActions = actions }))
              case result of
                (Left e) -> do
                  $(logError) $ "Failed to run transaction: " <> (T.pack . show) e
                  --addLogToDeploymentInstance deploymentKey $ "Failed to run transaction: " <> (pack . show) e
                  --setDeploymentInstanceStatus deploymentKey Failed
                  pure False
                (Right _) -> do
                  --setDeploymentInstanceStatus deploymentKey (if target == Deploy then Deployed else Created)
                  pure True

sendLogRequest :: Text -> Config -> Loc -> LogSource -> LogLevel -> LogStr -> IO ()
sendLogRequest deploymentId cfg loc src lvl msg = appTIO f cfg where
  f :: AppT ()
  f = do
    let str = (T.strip . T.pack . BS.unpack . fromLogStr) $ defaultLogStr loc src lvl msg
    if T.null str then pure () else do
      $(logInfo) str
      deploymentEnv <- asks $ getEnvFor DeploymentService
      _ <- withTokenVariable $ \token -> do
        defaultRetryClientC deploymentEnv $ D.postInstanceLog deploymentId str (BearerWrapper token)
      pure ()

setDeploymentInstanceStatus :: JobserviceMessageMeta -> DeploymentStatus -> AppT (Either String ())
setDeploymentInstanceStatus (JobserviceMessageMeta { deploymentId = dId, Jobservice.Models.templateId = tId, .. }) status = do
  deploymentEnv <- asks $ getEnvFor DeploymentService
  nEnv <- asks $ getEnvFor NotificationAPI
  ts <- getUnixIntTime
  res <- withTokenVariable $ \token -> do
    _ <- defaultRetrySClient nEnv $ postEventPayload (InstanceStatus {eventTimestamp=ts, eventTargetUser=fromMaybe "" deploymentUserId, eventStatus=status, eventGroup=deploymentGroup, eventDeployment=tId, eventAuthor=deploymentAuthorId}) (BearerWrapper token)
    defaultRetryClient deploymentEnv (patchDeploymentInstance dId
      (DeploymentPatch {patchInstanceVMLinks=Nothing, patchInstanceState=Just status, patchInstanceNetworkMap=Nothing, patchInstanceDeployConfig=Nothing}) (BearerWrapper token))
  case res of
    (Left tokenError)          -> pure $ Left tokenError
    (Right (Left clientError)) -> (pure . Left . show) clientError
    (Right (Right ()))         -> (pure . pure) ()
