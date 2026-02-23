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
import           Jobservice.Models
import           Network.AMQP
import           Proxmox.Deploy.Models.Config.VM
import           Redis.Common
import           Redis.Environment
import           Servant.Client
import           Service.Config
import           Service.Environment
import           System.Environment
import           System.Exit
import           System.Random

genericFormattedLock :: Message -> Text -> Bool -> AppT a -> AppT ()
genericFormattedLock msg key resendTask f' = do
  let lockKey = T.unpack key
  $(logDebug) $ "Checking key " <> key
  v <- getValue' lockKey
  case v of
    Nothing -> do
      $(logDebug) $ "Key " <> key <> " is not found. Processing next..."
      cacheValue' lockKey "lock" (Just 600)
      _ <- f'
      deleteValue' lockKey
      pure ()
    (Just _) -> do
      $(logInfo) "Deployment action task is locked."
      $(logDebug) $ "Lock key " <> key <> " is found."
      when resendTask $ do
        $(logInfo) "Resending task."
        r <- asks rabbitConnection
        chan <- liftIO $ openChannel r
        _ <- liftIO $ publishMsg chan "jobserviceExchange" "" msg
        liftIO $ closeChannel chan

genericDeploymentLock :: Message -> Text -> Bool -> AppT a -> AppT ()
genericDeploymentLock msg deploymentId resendTask f' = do
  let lockKey = "deployment_action_" <> deploymentId
  genericFormattedLock msg lockKey resendTask f'

f :: TVar Int -> (Message, Envelope) -> AppT ()
f deploymentsC (msg, env) = do
  randomDelay <- liftIO $ randomRIO (1_000_000, 3_000_000)
  $(logDebug) $ "Waiting for " <> (T.pack . show) (randomDelay `div` 1_000_000) <> " seconds."
  liftIO $ threadDelay randomDelay
  $(logDebug) "Starting decoding message"
  let decodeRes = eitherDecode (msgBody msg)
  $(logDebug) $ "Decoded into " <> (T.pack . show) decodeRes
  case decodeRes of
    (Left e) -> do
      $(logError) $ "Decode error: " <> pack e
    (Right (JobserviceUpdateUsedImages {})) -> do
      let lockKey = "image_usage_lock"
      v <- getValue' lockKey
      case v of
        Nothing -> do
          cacheValue' lockKey "lock" (Just 600)
          cacheUsedImages
          deleteValue' lockKey
        (Just _) -> do
          $(logInfo) "Image task is locked. Skipping task."
          pure ()
    (Right (JobserviceAllocateNode deploymentId)) -> do
      _ <- genericDeploymentLock msg deploymentId False $ do
        let lockKey = "allocate_node_lock"
        v <- getValue' lockKey
        case v of
          Nothing -> do
            cacheValue' lockKey "lock" (Just 600)
            allocateNode (env, msg) deploymentId
            deleteValue' lockKey
          (Just _) -> do
            $(logInfo) "Task is locked. Recreating message"
            r <- asks rabbitConnection
            chan <- liftIO $ openChannel r
            _ <- liftIO $ publishMsg chan "jobserviceExchange" "" msg
            liftIO $ closeChannel chan
      pure ()
    (Right (JobserviceDeployInstance deploymentId)) -> do
      _ <- genericDeploymentLock msg deploymentId False $ do
        let lockKey = "deploy_task_lock"
        v <- getValue' lockKey
        case v of
          Nothing -> do
            deploymentsInProgress <- liftIO $ readTVarIO deploymentsC
            deploymentLimit <- asks maxDeployments
            if deploymentsInProgress >= deploymentLimit then do
              $(logInfo) "Active deployments limit. Recreating message"
              r <- asks rabbitConnection
              chan <- liftIO $ openChannel r
              _ <- liftIO $ publishMsg chan "jobserviceExchange" "" msg
              liftIO $ closeChannel chan
              pure ()
            else do
              (liftIO . atomically) $ modifyTVar' deploymentsC (+1)
              cacheValue' lockKey "lock" (Just 10)
              $(logInfo) $ "Deploying " <> deploymentId
              deployInstance env deploymentId
              (liftIO . atomically) $ modifyTVar' deploymentsC (\v' -> v' - 1)
          (Just _) -> do
            $(logInfo) "Task is locked. Recreating message"
            r <- asks rabbitConnection
            chan <- liftIO $ openChannel r
            _ <- liftIO $ publishMsg chan "jobserviceExchange" "" msg
            liftIO $ closeChannel chan
      pure ()
    (Right (JobserviceDestroyInstance deploymentId)) -> do
      _ <- genericDeploymentLock msg deploymentId True $ do
        deploymentsInProgress <- liftIO $ readTVarIO deploymentsC
        deploymentLimit <- asks maxDeployments
        if deploymentsInProgress >= deploymentLimit then do
          $(logInfo) "Active deployments limit. Recreating message"
          r <- asks rabbitConnection
          chan <- liftIO $ openChannel r
          _ <- liftIO $ publishMsg chan "jobserviceExchange" "" msg
          liftIO $ closeChannel chan
          pure ()
        else do
          (liftIO . atomically) $ modifyTVar' deploymentsC (+1)
          _ <- liftIO $ do
            randomDelay <- randomRIO (0_000_000, 5_000_000) :: IO Int
            threadDelay randomDelay
          $(logInfo) $ "Destroying " <> deploymentId
          destroyInstance env deploymentId
          (liftIO . atomically) $ modifyTVar' deploymentsC (\v' -> v' - 1)
      pure ()
    (Right (JobservicePower deploymentId powerOn mask)) -> do
      genericFormattedLock msg ("deployment_power_task_" <> deploymentId) False $ do
        jobservicePower env deploymentId powerOn mask
    (Right (JobserviceSnapshot {deploymentSnapshot=snapName, deploymentDelete=delete, deploymentId=deploymentId, deploymentMask=mask, deploymentSnapshotComment=comment})) -> do
      genericFormattedLock msg ("deployment_snapshot_" <> deploymentId) False $ do
        jobserviceSnapshot deploymentId snapName delete mask comment
    (Right (JobserviceRollback {deploymentSnapshot=snapName, deploymentId=deploymentId, deploymentMask=mask})) -> do
      genericFormattedLock msg ("deployment_snapshot_" <> deploymentId) False $ do
        jobserviceRollback deploymentId snapName mask
  $(logDebug) $ "Finished message handle, acknowledging"
  liftIO $ ackEnv env

runCommand :: AppOpts -> IO ()
runCommand AppOpts { debugOn=debug } = let

  getTasks :: Channel -> Text -> (TVar Int) -> Int -> TQueue (Message, Envelope) -> IO ()
  getTasks channel queue activeThreads threadsAmount q = do
    _ <- consumeMsgs channel queue Ack $ \e@(_,env) -> do
      activeThreads' <- readTVarIO activeThreads
      if activeThreads' >= threadsAmount then do
        putStrLn "Pool is full"
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
