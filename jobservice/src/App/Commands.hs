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
{-# LANGUAGE NumericUnderscores  #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
module App.Commands (runCommand) where

import           Api
import           Api.Keycloak.Models
import           Api.Keycloak.Token
import           Api.Retry
import           App.Types
import           Auth.Token
import           Config
import           Control.Concurrent
import qualified Control.Concurrent.Async        as A
import           Control.Concurrent.Async.Pool
import           Control.Concurrent.STM
import           Control.Concurrent.STM.TVar
import           Control.Exception
import           Control.Monad                   (forever, when)
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8      as LBS
import           Data.Functor                    ((<&>))
import           Data.List                       (nub)
import           Data.Maybe
import           Data.Text                       (Text, pack)
import qualified Data.Text                       as T
import           Deployment.Client
import           Deployment.Models.Deployment
import           Handler.AllocateNode
import           Handler.Deployment
import           Handler.ImageUsage
import           Handler.Power
import           Handler.Snapshot
import           Jobservice.Client
import qualified Jobservice.Client               as J
import           Jobservice.Models
import           Network.AMQP
import           Proxmox.Deploy.Models.Config.VM
import           Redis.Common
import           Redis.Environment
import           Redis.Lock
import           Servant.Client
import           Service.Config
import           Service.Environment
import           System.Environment
import           System.Exit
import           System.Random
import           Utils.Time

genericFormattedLock :: Envelope -> Message -> Text -> Bool -> AppT a -> AppT ()
genericFormattedLock env msg key resendTask f' = let
  fail_ :: AppT ()
  fail_ = do
    $(logDebug) "Deployment action task is locked."
    $(logDebug) $ "Lock key " <> key <> " is found."
    when resendTask $ do
      $(logDebug) "Resending task."
      recreateMessageWithDelay env msg
  in do
  redisNXLockWrapper (T.unpack key) 600 (getUnixIntTime <&> fromIntegral) fail_ (void f')

genericDeploymentLock :: Envelope -> Message -> Text -> Bool -> AppT a -> AppT ()
genericDeploymentLock env msg deploymentId resendTask f' = do
  let lockKey = jobserviceLockKey GenericLock deploymentId
  genericFormattedLock env msg lockKey resendTask f'

recreateMessageWithDelay :: Envelope -> Message -> AppT ()
recreateMessageWithDelay env msg = do
  liftIO $ ackEnv env
  liftIO $ threadDelay 500_000
  r <- asks rabbitConnection
  chan <- liftIO $ openChannel r
  _ <- liftIO $ publishMsg chan "jobserviceExchange" "" msg
  liftIO $ closeChannel chan

raceTask :: Envelope -> Maybe Text -> Config -> AppT m -> AppT ()
raceTask env taskKey' cfg task' = let
  err :: SomeException -> IO ()
  err _ = do
    _ <- flip appTIO cfg $ do
      $(logWarn) $ "Task " <> fromMaybe "-" taskKey' <> " cancelled."
    pure ()

  raceLock :: Text -> AppT ()
  raceLock taskKey = do
    jobserviceEnv <- asks $ getEnvFor JobserviceAPI
    statusRes <- withTokenVariable $ \t -> do
      defaultRetryClientC jobserviceEnv $ setTaskStatus taskKey "running" (BearerWrapper t)
    case statusRes of
      (Right (Right _)) -> waitForCancel taskKey
      _anyError         -> raceLock taskKey

  waitForCancel :: Text -> AppT ()
  waitForCancel taskKey = do
    jobserviceEnv <- asks $ getEnvFor JobserviceAPI
    taskCannelled <- withTokenVariable $ \t -> do
      defaultRetryClientC jobserviceEnv $ isTaskReachedStatus taskKey "cancelled" (BearerWrapper t)
    case taskCannelled of
      (Right (Right True)) -> pure ()
      (Right (Right False)) -> liftIO (threadDelay 1_000_000) >> waitForCancel taskKey
      _anyError -> liftIO (threadDelay 500_000) >> waitForCancel taskKey

  in do
    case taskKey' of
      Nothing -> void task'
      (Just taskKey) -> do
        jobserviceEnv <- asks $ getEnvFor JobserviceAPI
        isCancelled <- withTokenVariable $ \t -> do
           defaultRetryClient jobserviceEnv $ J.isTaskReachedStatus taskKey "cancelled" (BearerWrapper t)
        case isCancelled of
          Right (Right False) -> do
            _ <- liftIO $ A.race (catch (void $ appTIO (raceLock taskKey) cfg) err) (catch (void $ appTIO task' cfg) err)
            _ <- withTokenVariable $ \t -> do
               defaultRetryClient jobserviceEnv $ J.deleteTask taskKey (BearerWrapper t)
            liftIO $ ackEnv env
          Right (Right True) -> do
            $(logWarn) $ "Task " <> taskKey <> " is already cancelled."
            liftIO $ ackEnv env
          _anyError -> do
            liftIO $ nackEnv env

f :: TVar Int -> (Message, Envelope) -> AppT ()
f deploymentsC (msg, env) = do
  $(logDebug) "Starting decoding message"
  let decodeRes = eitherDecode (msgBody msg)
  $(logDebug) $ "Decoded into " <> (T.pack . show) decodeRes
  case decodeRes of
    (Left e) -> do
      $(logError) $ "Decode error: " <> pack e
      liftIO $ ackEnv env
    (Right (JobserviceTask taskKey _ JobserviceUpdateUsedImages {})) -> do
       cfg <- ask
       raceTask env taskKey cfg $ cacheUsedImages
    (Right (JobserviceTask taskKey (Just meta@(JobserviceMessageMeta { targetUserId = Just _ })) (JobserviceAllocateNode {}))) -> do
      genericFormattedLock env msg "allocate_node_lock" True $ do
        cfg <- ask
        raceTask env taskKey cfg $ allocateNode (env, msg) meta
    (Right (JobserviceTask taskKey (Just meta@JobserviceMessageMeta { deploymentId = deploymentId, targetUserId = Just _ }) JobserviceDeployInstance {})) -> do
      deploymentsInProgress <- liftIO $ readTVarIO deploymentsC
      deploymentLimit <- asks maxDeployments
      if deploymentsInProgress >= deploymentLimit then do
        $(logInfo) "Active deployments limit. Recreating message"
        recreateMessageWithDelay env msg
      else do
        _ <- genericDeploymentLock env msg deploymentId False $ do
          (liftIO . atomically) $ modifyTVar' deploymentsC (+1)
          _ <- liftIO $ do
            randomDelay <- randomRIO (0_000_000, 5_000_000) :: IO Int
            threadDelay (randomDelay + min 30 (5_000_000 * deploymentsInProgress))
          $(logInfo) $ "Deploying " <> deploymentId
          cfg <- ask
          _ <- raceTask env taskKey cfg $ deployInstance env meta
          (liftIO . atomically) $ modifyTVar' deploymentsC (\v' -> v' - 1)
        pure ()
    (Right (JobserviceTask taskKey (Just meta@JobserviceMessageMeta { deploymentId = deploymentId, targetUserId = Just _ }) JobserviceDestroyInstance {})) -> do
      _ <- genericDeploymentLock env msg deploymentId True $ do
        deploymentsInProgress <- liftIO $ readTVarIO deploymentsC
        deploymentLimit <- asks maxDeployments
        if deploymentsInProgress >= deploymentLimit then do
          $(logInfo) "Active deployments limit. Recreating message"
          recreateMessageWithDelay env msg
        else do
          (liftIO . atomically) $ modifyTVar' deploymentsC (+1)
          _ <- liftIO $ do
            randomDelay <- randomRIO (0_000_000, 5_000_000) :: IO Int
            threadDelay randomDelay
          $(logInfo) $ "Destroying " <> deploymentId
          cfg <- ask
          _ <- raceTask env taskKey cfg $ destroyInstance env meta
          (liftIO . atomically) $ modifyTVar' deploymentsC (\v' -> v' - 1)
      pure ()
    (Right (JobserviceTask taskKey (Just m@(JobserviceMessageMeta { .. })) (JobservicePower powerOn mask))) -> do
      genericFormattedLock env msg (jobserviceLockKey PowerLock deploymentId) False $ do
        cfg <- ask
        raceTask env taskKey cfg $ jobservicePower m env powerOn mask
    (Right (JobserviceTask taskKey (Just m@(JobserviceMessageMeta { .. })) JobserviceSnapshot {deploymentSnapshot=snapName, deploymentDelete=delete, deploymentMask=mask, deploymentSnapshotComment=comment})) -> do
      genericFormattedLock env msg (jobserviceLockKey SnapshotLock deploymentId) False $ do
        cfg <- ask
        raceTask env taskKey cfg $ jobserviceSnapshot m snapName delete mask comment
    (Right (JobserviceTask taskKey (Just m@(JobserviceMessageMeta { .. })) JobserviceRollback {deploymentSnapshot=snapName, deploymentMask=mask})) -> do
      genericFormattedLock env msg (jobserviceLockKey SnapshotLock deploymentId) False $ do
        cfg <- ask
        raceTask env taskKey cfg $ jobserviceRollback m snapName mask
    (Right t) -> do
      $(logError) $ T.pack $ "Invalid task format: " <> show t
      liftIO $ ackEnv env

runCommand :: AppOpts -> IO ()
runCommand AppOpts { debugOn=debug } = let

  getTasks :: Channel -> Text -> (TVar Int) -> Int -> TQueue (Message, Envelope) -> IO ()
  getTasks channel queue activeThreads threadsAmount q = do
    _ <- consumeMsgs channel queue Ack $ \e@(_,env) -> do
      activeThreads' <- readTVarIO activeThreads
      if activeThreads' >= threadsAmount then do
        threadDelay 500_000
        rejectEnv env True
      else do
        atomically $ writeTQueue q e
    pure ()

  callback :: Config -> Int -> QSemN -> (TVar Int) -> (TVar Int) -> TQueue (Message, Envelope) -> AppT ()
  callback cfg workerNum sem activeDeploymentsCounter activeThreadsCounter q = do
    forever $ do
      t <- (liftIO . atomically) $ readTQueue q
      $(logDebug) $ pack $ "Read TQueue [" <> show workerNum <> "]"
      liftIO $ bracket_
        (waitQSemN sem 1 >> atomically (modifyTVar' activeThreadsCounter (+1)))
        (atomically (modifyTVar' activeThreadsCounter (\x -> x - 1)) >> signalQSemN sem 1)
        (flip appTIO cfg $ f activeDeploymentsCounter t)
      $(logDebug) $ pack $ "Finished TQueue task [" <> show workerNum <> "]"
  in do
  debugEnv <- lookupEnv "DEBUG" <&> fmap (== "1")
  let logFunction = if debug || debugEnv == Just True then defaultLogF else filterLogF LevelInfo

  _ <- do
    e <- getEnvironment
    flip runLoggingT logFunction $ $(logDebug) $ "Current environment: " <> (pack . show) e

  redis <- redisConnectionFromEnv
  when (isNothing redis) $ do
    flip runLoggingT logFunction $ $(logError) "Failed to build Redis connection"
    exitWith (ExitFailure 1)
  deployZone <- runLoggingT
    (requireEnv "DEPLOY_SDN_ZONE" ($(logError) "DEPLOY_SDN_ZONE is not set" >> (liftIO . exitWith) (ExitFailure 1))) logFunction
  creds <- runLoggingT requireKeycloakClient logFunction
  tokenV <- createTokenVar
  (authUrl, authManager) <- runLoggingT (requireServiceEnv "AUTH") logFunction
  (depUrl, depManager) <- runLoggingT (requireServiceEnv "DEPLOYMENT") logFunction
  (jobserviceUrl, jobserviceManager) <- runLoggingT (requireServiceEnv "JOBSERVICE") logFunction
  (clusterUrl, clusterManager) <- runLoggingT (requireServiceEnv "CLUSTER") logFunction
  (notificationUrl, notificationManager) <- runLoggingT (requireServiceEnv "NOTIFICATION") logFunction

  threadsAmount <- runLoggingT (lookupEnvDefault "THREADS_AMOUNT" 4) logFunction
  concurrentDeployments <- runLoggingT (lookupEnvDefault "CONCURRENT_DEPLOYMENTS" 2) logFunction
  amqpConn <- runLoggingT (requireRabbitMQCreds openConnection') logFunction
  channel <- openChannel amqpConn
  (queue, _, _) <- declareQueue channel newQueue { queueName = "jobserviceQueue" }
  declareExchange channel newExchange { exchangeName = "jobserviceExchange", exchangeType = "direct" }
  bindQueue channel "jobserviceQueue" "jobserviceExchange" ""

  let config = Config { serviceCredentials=creds
    , logFunction=logFunction
    , authToken=tokenV
    , authEnv=mkClientEnv authManager authUrl
    , deploymentEnv=mkClientEnv depManager depUrl
    , authFunctions=genericTokenFunctions logFunction creds (mkClientEnv authManager authUrl)
    , redisConnection=fromJust redis
    , deploySDNZone=pack deployZone
    , jobserviceApiEnv=mkClientEnv jobserviceManager jobserviceUrl
    , clusterEnv=mkClientEnv clusterManager clusterUrl
    , rabbitConnection=amqpConn
    , maxDeployments = concurrentDeployments
    }
  _ <- flip runLoggingT logFunction $ $(logInfo) "Starting server!"
  activeDeploymentsCounter <- newTVarIO (0 :: Int)
  activeThreadsCounter <- newTVarIO 0
  taskPool <- createPool
  tasksQueue <- newTQueueIO
  sem <- newQSemN threadsAmount
  --pool <- createPool (\e@(env, _) -> f activeDeploymentsCounter e >> liftIO (ackEnv env)) (`appTIO` config) threadsAmount
  --_ <- consumeMsgs channel queue Ack (flip appTIO config . callback pool)
  _ <- withTaskGroupIn taskPool (threadsAmount + 1) $ \g -> do
    _ <- async g (getTasks channel queue activeThreadsCounter threadsAmount tasksQueue)
    mapM_ (\n -> async g . flip appTIO config $ callback config n sem activeDeploymentsCounter activeThreadsCounter tasksQueue) [1..threadsAmount]
    forever $ threadDelay 500_000
  return ()
