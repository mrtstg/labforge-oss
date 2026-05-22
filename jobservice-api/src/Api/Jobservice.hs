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
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TypeOperators       #-}
module Api.Jobservice
  ( jobserviceServer
  , sendMessage
  ) where

import           Api                            (PagedResponse (..))
import           Api.Keycloak.Models
import           Api.Keycloak.Models.Introspect
import           Auth.Token
import           Config
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8     as LBS
import           Data.Functor                   ((<&>))
import           Data.Maybe
import           Data.Text                      (Text)
import qualified Data.Text                      as T
import           Data.UUID.V4                   (nextRandom)
import           Database
import           Database.Persist
import           Jobservice.Models
import           Jobservice.Schema
import           Models.JSONError
import           Network.AMQP
import           Redis.Common
import           Servant
import           Utils.Time

jobserviceServer :: ServerT JobserviceAPI AppT
jobserviceServer = sendMessage :<|> getHeldImages :<|> getImageUsage :<|> isDeploymentLocked :<|> deleteTask :<|> isTaskReachedStatus :<|> setTaskStatus :<|> getTask :<|> getPagedTasks

deleteTask :: Text -> BearerWrapper -> AppT ()
deleteTask taskId (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  taskData <- runDB $ get (TaskDataKey taskId)
  case taskData of
    Nothing -> pure ()
    (Just (TaskData { .. })) -> do
      if "jobservice-task-admin" `notElem` tokenRealmRoles && taskDataAuthor /= Just (fromMaybe "" tokenUUID) then do
        sendJSONError err403 (JSONError "forbidden" "You do not own this task!" $ object ["message" .= String "Вы не владеете данной задачей."])
      else runDB $ deleteWhere [ TaskDataId ==. TaskDataKey taskId ]

isTaskReachedStatus :: Text -> Text -> BearerWrapper -> AppT Bool
isTaskReachedStatus taskId status (BearerWrapper token) = do
  _ <- requireRealmRoles token ["jobservice-send"]
  task <- runDB $ get (TaskDataKey taskId)
  case task of
    Nothing                                      -> pure True
    (Just (TaskData { taskDataStatus=status' })) -> do
      ts <- getUnixIntTime
      runDB $ updateWhere [ TaskDataId ==. TaskDataKey taskId ] [ TaskDataLastUpdate =. ts ]
      pure $ status == status'

setTaskStatus :: Text -> Text -> BearerWrapper -> AppT ()
setTaskStatus taskId status (BearerWrapper token) = do
  _ <- requireRealmRoles token ["jobservice-send"]
  ts <- getUnixIntTime
  runDB $ updateWhere [ TaskDataId ==. TaskDataKey taskId ] [ TaskDataStatus =. status, TaskDataLastUpdate =. ts ]

getTask :: Text -> BearerWrapper -> AppT JobserviceTaskData
getTask taskId (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  taskData <- runDB $ get (TaskDataKey taskId)
  case taskData of
    Nothing -> sendJSONError err404 (JSONError "notFound" "Task not found" Null)
    (Just (TaskData { .. })) -> do
      if "jobservice-task-admin" `notElem` tokenRealmRoles && taskDataAuthor /= Just (fromMaybe "" tokenUUID) then do
        sendJSONError err403 (JSONError "forbidden" "You do not own this task!" $ object ["message" .= String "Вы не владеете данной задачей."])
      else pure (JobserviceTaskData {jobserviceTask=taskDataTask, jobserviceTaskAuthor=taskDataAuthor, jobserviceTaskGroup=taskDataGroup, jobserviceTaskKey=taskId, jobserviceTaskMeta=taskDataMetadata, jobserviceTaskStatus=taskDataStatus, jobserviceTaskTimestamp=taskDataTimestamp})

getPagedTasks :: Maybe Int -> BearerWrapper -> AppT (PagedResponse [JobserviceTaskData])
getPagedTasks pageN (BearerWrapper token) = do
  ~(ActiveToken { .. }) <- requireToken token
  let page = fromMaybe 1 pageN
  let pageSize = 15
  let limits = [ LimitTo pageSize, OffsetBy $ (page - 1) * pageSize, Desc TaskDataStatus, Asc TaskDataTimestamp ]
  let filters = if "jobservice-task-admin" `elem` tokenRealmRoles then [] else [ TaskDataAuthor ==. tokenUUID ]
  totalTasks <- runDB $ count filters
  tasksData <- runDB $ selectList filters limits
  pure PagedResponse {responseTotal=totalTasks, responsePageSize=pageSize, responseObjects=map (\(Entity (TaskDataKey taskKey) (TaskData { .. })) -> JobserviceTaskData {jobserviceTaskTimestamp=taskDataTimestamp, jobserviceTaskStatus=taskDataStatus, jobserviceTaskMeta=taskDataMetadata, jobserviceTaskKey=taskKey, jobserviceTaskGroup=taskDataGroup, jobserviceTaskAuthor=taskDataAuthor, jobserviceTask=taskDataTask}) tasksData}

isDeploymentLocked :: Text -> JobserviceLockType -> BearerWrapper -> AppT Bool
isDeploymentLocked deploymentId AnyLock (BearerWrapper token) = do
  _ <- requireToken token
  mapM (getValue' . T.unpack . (`jobserviceLockKey` deploymentId)) [GenericLock, PowerLock, SnapshotLock] <&> any isJust
isDeploymentLocked deploymentId specifiedKey (BearerWrapper token) = do
  _ <- requireToken token
  let lockKey = T.unpack $ jobserviceLockKey specifiedKey deploymentId
  getValue' lockKey <&> isJust

sendMessage :: JobserviceTask -> BearerWrapper -> AppT JobserviceTaskResponse
sendMessage (JobserviceTask conflictKey meta msg') (BearerWrapper token) = do
  _ <- requireRealmRoles token ["jobservice-send"]

  keyTaken <- maybe (pure False) (\v -> runDB $ exists [ TaskDataConfictKey ==. Just v ]) conflictKey
  if keyTaken then sendJSONError (err400 { errHTTPCode = 429 }) (JSONError "taskConflict" "Conflict key is taken" (object ["message" .= String "Подобная задача уже находится в очереди или выполняется"])) else do
    taskKey <- liftIO nextRandom <&> (T.pack . show)
    ts <- getUnixIntTime

    r <- asks rabbitConnection
    chan <- liftIO $ openChannel r
    let group' = actionGroup =<< meta
    let author' = authorId =<< meta
    _ <- runDB $ insertKey (TaskDataKey taskKey) (TaskData {taskDataTimestamp=ts, taskDataTask=msg', taskDataStatus="queued", taskDataMetadata=meta, taskDataGroup=group', taskDataAuthor=author', taskDataLastUpdate=ts, taskDataConfictKey=conflictKey})
    let msg = newMsg { msgBody = encode (JobserviceTask (Just taskKey) meta msg'), msgDeliveryMode = Just NonPersistent }
    _ <- liftIO $ publishMsg chan "jobserviceExchange" "" msg
    liftIO $ closeChannel chan
    pure (JobserviceTaskResponse taskKey)

getImageUsage :: Text -> BearerWrapper -> AppT [JobserviceImageUsageData]
getImageUsage imageName (BearerWrapper token) = do
  _ <- requireManyRealmRoles token [["image-view"], ["image-admin"]]
  redisV <- getValue' . jobserviceUsedImageKey . T.unpack $ imageName
  case redisV of
    Nothing        -> pure []
    (Just payload) -> do
      case eitherDecode (LBS.fromStrict payload) of
        (Left e) -> do
          $(logError) $ "Image usage decode error: " <> (T.pack . show) e
          sendJSONError err500 (JSONError "internalError" "Failed to decode data" Null)
        (Right (usages :: [JobserviceImageUsageData])) -> pure usages

getHeldImages :: BearerWrapper -> AppT [String]
getHeldImages (BearerWrapper token) = do
  _ <- requireManyRealmRoles token [["image-view"], ["image-admin"]]
  redisV <- getValue' jobserviceUsedImagesKey
  case redisV of
    Nothing        -> sendJSONError err404 (JSONError "notFound" "" Null)
    (Just payload) -> do
      case eitherDecode (LBS.fromStrict payload) of
        (Left e) -> do
          $(logError) $ "Held images decode error: " <> (T.pack . show) e
          sendJSONError err500 (JSONError "internalError" "Failed to decode data" Null)
        (Right (images :: [String])) -> pure images
