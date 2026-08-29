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
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TupleSections       #-}
{-# LANGUAGE TypeOperators       #-}
module Api.Pages
  ( pagesServer
  , PagesAPI
  ) where

import           Api
import           Api.Keycloak.Models
import           Api.Keycloak.Models.Group                (FoundGroup (groupName))
import           Api.Keycloak.Models.Introspect
import           Api.Keycloak.Models.User
import           Api.Keycloak.Utils
import           Api.Redirect
import           Api.Retry
import           Api.Utils
import qualified Auth.Client                              as Auth
import           Config
import           Control.Concurrent.STM.TVar
import           Control.Monad.Logger
import           Control.Monad.Reader
import           Data.Aeson
import           Data.Aeson.Encode.Pretty
import qualified Data.Aeson.KeyMap                        as KM
import qualified Data.ByteString.Char8                    as BS
import qualified Data.ByteString.Lazy.Char8               as LBS
import           Data.Either
import           Data.Functor                             ((<&>))
import           Data.List                                (intercalate, nub)
import qualified Data.Map                                 as M
import           Data.Maybe
import           Data.Text                                (Text)
import qualified Data.Text                                as T
import qualified Data.Text.Encoding                       as T
import qualified Data.Text.Lazy                           as LT
import           Database.Persist
import qualified Deployment.Client                        as C
import qualified Deployment.Client                        as Deployment
import           Deployment.Models.Deployment
import           Deployment.Models.Stats
import qualified Jobservice.Client                        as J
import qualified Jobservice.Client                        as Jobservice
import           Jobservice.Models
import           Kroki.Client
import           Models.JSONError
import           Network.URI.Encode                       (encodeText)
import           Proxmox.Deploy.Models.Config
import           Proxmox.Deploy.Models.Config.Deploy
import           Proxmox.Deploy.Models.Config.DeployAgent
import           Proxmox.Deploy.Models.Config.Network
import           Proxmox.Deploy.Models.Config.Template
import           Proxmox.Deploy.Models.Config.VM
import           Proxmox.Models.NetworkInterface
import           Roles
import           Servant
import           Servant.Client
import           Servant.HTML.Blaze
import           Service.Environment
import           Templates.Base
import           Templates.Components
import           Text.Blaze.Html
import           Text.Blaze.Html.Renderer.Text            (renderHtml)
import           Text.Hamlet
import           Text.Printf
import           Utils
import           Utils.Time

type AuthHeader' = Header "Authorization" BearerWrapper

type PagesAPI = AuthHeader' :> QueryParam "page" Int :> Get '[HTML] Html
  :<|> "notfound" :> Get '[HTML] Html
  :<|> "internalerror" :> Get '[HTML] Html
  :<|> "norights" :> Get '[HTML] Html
  :<|> "instance" :> Capture "instanceID" Text :> AuthHeader' :> QueryParam "power" Text :> Get '[HTML] Html
  :<|> "instance" :> Capture "instanceID" Text :> "schema" :> AuthHeader' :> Get '[HTML] Html
  :<|> "instance" :> Capture "instanceID" Text :> "delete" :> AuthHeader' :> Get '[HTML] Html
  :<|> "vnc" :> Capture "vmPort" Text :> AuthHeader' :> Get '[HTML] Html
  :<|> "vnc" :> Capture "vmPort" Text :> "full" :> AuthHeader' :> Get '[HTML] Html
  :<|> "deployment" :> "create" :> AuthHeader' :> Get '[HTML] Html
  :<|> "deployment" :> "my" :> QueryParam "page" Int :> AuthHeader' :> Get '[HTML] Html
  :<|> "deployment" :> Capture "deploymentId" Int :> "delete" :> AuthHeader' :> Get '[HTML] Html
  :<|> "deployment" :> Capture "deploymentId" Int :> "edit" :> AuthHeader' :> Get '[HTML] Html
  :<|> "image" :> Capture "imageId" Int :> "delete" :> AuthHeader' :> Get '[HTML] Html
  :<|> "image" :> "my" :> QueryParam "page" Int :> AuthHeader' :> Get '[HTML] Html
  :<|> "image" :> "create" :> QueryParam "name" Text :> QueryParam "id" Int :> AuthHeader' :> Get '[HTML] Html
  :<|> "deployment" :> Capture "deploymentId" Int :> "instances" :> QueryParam "page" Int :> QueryParam "refresh" Int :> QueryParam "group" Text :> AuthHeader' :> Get '[HTML] Html
  :<|> "deployment" :> Capture "deploymentId" Int :> "copy" :> AuthHeader' :> Get '[HTML] Html
  :<|> "instance" :> Capture "instanceID" Text :> "power" :> AuthHeader' :> QueryParam "power" Int :> Get '[HTML] Html
  :<|> "tasks" :> QueryParam "page" Int :> AuthHeader' :> Get '[HTML] Html
  :<|> "tasks" :> Capture "taskId" Text :> "cancel" :> AuthHeader' :> Get '[HTML] Html
  :<|> "tasks" :> "group" :> Capture "groupId" Text :> "cancel" :> AuthHeader' :> Get '[HTML] Html

globalDecoder' :: AppT (Either ClientError a) -> AppT a
globalDecoder' v = do
  r <- v
  globalDecoder (tryDecodeError r)

sendHTMLError :: Html -> AppT a
sendHTMLError body = throwError $ ServerError {errReasonPhrase="", errHeaders=[("Content-Type", "text/html")], errHTTPCode=200, errBody=(LBS.fromStrict . T.encodeUtf8 . LT.toStrict . renderHtml) body}

globalDecoder :: DecodeResult a -> AppT a
globalDecoder (DecodedResult a) = pure a
globalDecoder (DecodedError code e@(JSONError { .. })) = do
  $(logError) $ "Got decoded error: " <> (T.pack . show) e
  if code == 400 then sendHTMLError (badRequestTemplate e) else
    sendJSONError (ServerError {errReasonPhrase="", errHeaders=[], errHTTPCode=code, errBody=""}) e
globalDecoder (UndecodedError code b) = throwError $ ServerError {errReasonPhrase="", errHeaders=[], errHTTPCode=code, errBody=LBS.fromStrict b}
globalDecoder (OtherError e) = do
  $(logError) $ "Got other error: " <> (T.pack .  show) e
  sendJSONError err500 (JSONError "" "" Null)

pagesServer :: ServerT PagesAPI AppT
pagesServer = indexPage
  :<|> notFound
  :<|> internalError
  :<|> noRights
  :<|> instancePage
  :<|> instanceSchemaPage
  :<|> deleteInstancePage
  :<|> vncPage
  :<|> vncPageFull
  :<|> deploymentCreatePage
  :<|> deploymentListPage
  :<|> deleteDeploymentPage
  :<|> deploymentEditPage
  :<|> deleteImagePage
  :<|> imagesPage
  :<|> createImagePage
  :<|> deploymentInstancesPage
  :<|> copyDeploymentPage
  :<|> instancePowerPage
  :<|> tasksPage
  :<|> deleteTaskPage
  :<|> deleteTaskGroup

deleteTaskGroup :: Text -> Maybe BearerWrapper -> AppT Html
deleteTaskGroup groupId t = do
  token <- requireToken' t
  let ~(Just userToken) = t
  env <- asks $ getEnvFor JobserviceAPI
  _ <- globalDecoder' $ defaultRetryClient env (J.deleteGroupTask groupId userToken)
  addMessageToSession token "Группа задач отправлена на закрытие."
  tempRedirectTo "/tasks"

deleteTaskPage :: Text -> Maybe BearerWrapper -> AppT Html
deleteTaskPage taskId t = do
  token <- requireToken' t
  let ~(Just userToken) = t
  env <- asks $ getEnvFor JobserviceAPI
  _ <- globalDecoder' $ defaultRetryClient env (J.deleteTask taskId userToken)
  addMessageToSession token "Задача отправлена на досрочное закрытие."
  tempRedirectTo "/tasks"

tasksPage :: Maybe Int -> Maybe BearerWrapper -> AppT Html
tasksPage pageN t = do
  token <- requireToken' t
  let page = fromMaybe 1 pageN
  let ~(Just userToken) = t
  env <- asks $ getEnvFor JobserviceAPI
  deploymentEnv <- asks $ getEnvFor DeploymentService
  r@(PagedResponse {responseObjects=tasks}) <- globalDecoder' $ defaultRetryClient env (J.getPagedTasks pageN userToken)
  let userIds = nub $ mapMaybe (maybe Nothing targetUserId . jobserviceTaskMeta) tasks <> mapMaybe (maybe Nothing authorId . jobserviceTaskMeta) tasks
  let deploymentIds = mapMaybe (maybe Nothing (pure . Jobservice.Models.templateId) . jobserviceTaskMeta) tasks
  deploymentMap <- genericClientLoseGather deploymentIds (\did -> withTokenVariable' $ \t -> defaultRetryClientC deploymentEnv $ Deployment.getDeploymentTemplate did (BearerWrapper t))
  tasksUsers <- gatherUsers userIds
  let checkUser meta = maybe "" briefDisplayName $ M.lookup (maybe "" (fromMaybe "" . targetUserId) meta) tasksUsers
  let checkAuthor meta = maybe "" briefDisplayName $ M.lookup (maybe "" (fromMaybe "" . authorId) meta) tasksUsers
  let checkTemplate meta = maybe "-" templateTitle $ M.lookup (maybe 0 Jobservice.Models.templateId meta) deploymentMap
  let hasNext = hasNextPages page r
  ts <- getUnixIntTime
  (\v -> baseTemplate token Nothing (Just "Задачи") v (Just genericInstanceActionFormData)) [shamlet|
<div .container>
  $if null tasks
    <h1 .title.is-3>
      Нет доступных для просмотра задач!
  $else
    <div .is-flex.is-flex-direction-row.is-align-items-center>
      <div>
        <h1 .title.is-3> Задачи
    <div .table-container>
      <table .table.is-fullwidth>
        <thead>
          <tr>
            <th> Задача
            <th> Статус
            <th> Время в статусе (суммарное)
            <th> Автор
            <th> Пользователь
            <th> Развертывание
            <th> Стенд
            <th>
            <th>
        <tbody>
          $forall (JobserviceTaskData { .. }) <- tasks
            <tr>
              <td> #{ describeJobserviceTaskKind jobserviceTask }
              <td>
                $if jobserviceTaskStatus == "running"
                  <b> Выполняется
                $else
                  $if jobserviceTaskStatus == "queued"
                    <i> В очереди
                  $else
                    #{ jobserviceTaskStatus }
              <td> #{prettifyTaskLifetime $ ts - jobserviceTaskStatusTimestamp} (#{ prettifyTaskLifetime $ ts - jobserviceTaskTimestamp })
              <td> #{ checkAuthor jobserviceTaskMeta }
              <td> #{ checkUser jobserviceTaskMeta }
              <td>
                $case jobserviceTaskMeta
                  $of (Just (JobserviceMessageMeta { .. }))
                    <a href=/deployment/#{templateId}/instances> #{checkTemplate jobserviceTaskMeta}
                  $of _anyOther
                    -
              <td>
                $case jobserviceTaskMeta
                  $of (Just (JobserviceMessageMeta { .. }))
                    <a href="/instance/#{deploymentId}"> Открыть стенд
                  $of _anyOther
                    -
              <td>
                <a href=/tasks/#{jobserviceTaskKey}/cancel .button.is-outlined.is-warning> Прервать
              <td>
                $if isJust jobserviceTaskGroup
                  $case jobserviceTaskGroup
                    $of (Just group)
                      <a href=/tasks/group/#{group}/cancel .button.is-outlined.is-danger> Удалить группу
    <nav .pagination.is-centered>
      <ul .pagination-list>
        $if page /= 1
          <li>
            <a .pagination-link href=/tasks?page=#{preEscapedToHtml $ page - 1}> #{page - 1}
        <li>
          <a .pagination-link.is-current> #{page}
        $if hasNext
          <li>
            <a .pagination-link href=/tasks?page=#{preEscapedToHtml $ page + 1}> #{page + 1}
|]

deploymentInstancesPage :: Int -> Maybe Int -> Maybe Int -> Maybe Text -> Maybe BearerWrapper -> AppT Html
deploymentInstancesPage did pageN refreshFlag groupFlag t = do
  token <- requireToken' t
  let ~(Just userToken) = t
  env <- asks $ getEnvFor DeploymentService
  let page = unpackPage pageN
  let refreshValue = fromMaybe 0 refreshFlag
  let refresh = refreshValue == 1
  (DeploymentStats { .. }) <- globalDecoder' $ defaultRetryClientC env (C.getDeploymentInstancesStats did groupFlag userToken)
  r@(PagedResponse { responseObjects=instances, responseTotal=total }) <- globalDecoder' $ defaultRetryClientC env (C.getDeploymentTemplateInstances did (Just page) groupFlag userToken)
  authEnv <- asks $ getEnvFor AuthService
  allRoles <- withTokenVariable' $ \token' -> do
    globalDecoder' $ defaultRetryClientC authEnv (Auth.getAllGroups (BearerWrapper token'))
  let roleNames = map groupName allRoles
  userData <- gatherUsers (map briefDeploymentUser instances)
  let hasNext = hasNextPages page r
  let totallyEmpty = page == 1 && total == 0
  let group = fromMaybe "" groupFlag
  let (opts :: [(String, String)]) = [("x-init", "$watch('group', (newValue, oldValue) => { let u = new URL(document.URL); u.searchParams.delete('page'); u.searchParams.delete('refresh'); u.searchParams.delete('group'); u.searchParams.append('group', newValue); window.location.replace(u.href); })")]
  (\v -> baseTemplate token Nothing ((Just . T.unpack) $ if not . null $ instances then briefDeploymentTitle (head instances) <> ": стенды" else "Стенды") v (Just genericInstanceActionFormData)) [shamlet|
<div .container>
  <div .box.mb-3 x-data={group:null} *{opts}>
    <h2 .subtitle.is-5> Показывать для группы
    ^{genericLargeSelectForm "group" roleNames}
  $if totallyEmpty
    <h1 .title.is-3>
      $if T.length group > 0
        Нет развернутых стендов на группу #{group}!
      $else
        Нет развернутых стендов!
  $else
    <div .is-flex.is-flex-direction-row.is-align-items-center>
      <div>
        $if length instances > 0
          <h1 .title.is-3>
            $if T.length group > 0
              #{briefDeploymentTitle (head instances)}: стенды на группу #{group}
            $else
              #{briefDeploymentTitle (head instances)}: стенды
        $else
          <h1 .title.is-3> Стенды
      <div>
        <a .button href=/deployment/#{did}/instances?page=#{page}&refresh=#{abs $ refreshValue - 1}&group=#{encodeText group}>
          $if not refresh
            Включить автообновление
          $else
            Выключить автообновление
      $case groupFlag
        $of Nothing
        $of (Just group)
          $if T.length group > 0
            <div>
              <a .button href=/deployment/#{did}/instances?page=#{page}>
                Сбросить фильтр
    <div .box>
      $if createdAmount /= 0
        <p> Создано: #{createdAmount} / #{total}
        <progress class="progress" value="#{createdAmount}" max="#{total}">
      $if deployingAmount /= 0
        <p> Развертывается: #{deployingAmount} / #{total}
        <progress class="progress is-info" value="#{deployingAmount}" max="#{total}">
      $if deployedAmount /= 0
        <p> Развернуто: #{deployedAmount} / #{total}
        <progress class="progress is-success" value="#{deployedAmount}" max="#{total}">
      $if destroyingAmount /= 0
        <p> Уничтожается: #{destroyingAmount} / #{total}
        <progress class="progress is-warning" value="#{destroyingAmount}" max="#{total}">
      $if failedAmount /= 0
        <p> Произошла ошибка: #{failedAmount} / #{total}
        <progress class="progress is-danger" value="#{failedAmount}" max="#{total}">
    <div .columns.is-multiline>
    $forall (DeploymentInstanceBrief { .. }) <- instances
      <div .column>
        <div .card>
          <header .card-header>
            <p .card-header-title>
              $case M.lookup briefDeploymentUser userData
                $of (Just (BriefUser { .. }))
                  #{ fromMaybe "-" userFirstName } #{ fromMaybe "-" userLastName }
                $of Nothing
                  Пользователь #{briefDeploymentUser}
          <div .card-content>
            #{prettyDeployStatus briefDeploymentStatus}
            ^{genericInstanceActionForm briefDeploymentId}
          <footer .card-footer>
            <a .card-footer-item href=/instance/#{briefDeploymentId}> Открыть
            <a .card-footer-item href=/instance/#{briefDeploymentId}/delete> Удалить
    <nav .pagination.is-centered>
      <ul .pagination-list>
        $if page /= 1
          <li>
            <a .pagination-link href=/deployment/#{did}/instances?page=#{preEscapedToHtml $ page - 1}&group=#{encodeText group}> #{page - 1}
        <li>
          <a .pagination-link.is-current> #{page}
        $if hasNext
          <li>
            <a .pagination-link href=/deployment/#{did}/instances?page=#{preEscapedToHtml $ page + 1}&group=#{encodeText group}> #{page + 1}
$if refresh
  <script>
    $if totallyEmpty
      const url = new URL(window.location.href);
      url.searchParams.set('refresh', '0');
      window.location.href = url.href;
    $else
      setTimeout(function() {
        location.reload();
      }, 5000);
|]

deleteInstancePage :: Text -> Maybe BearerWrapper -> AppT Html
deleteInstancePage did t = do
  _ <- requireToken' t
  let ~(Just userToken) = t
  env <- asks $ getEnvFor DeploymentService
  (DeploymentInstance { .. }) <- globalDecoder' $ defaultRetryClientC env $ C.getDeploymentInstance did userToken
  _ <- globalDecoder' $ defaultRetryClientC env (C.callInstanceDestroy did userToken)
  tempRedirectTo $ "/deployment/" <> show instanceOf <> "/instances"

imagesPage :: Maybe Int -> Maybe BearerWrapper -> AppT Html
imagesPage pageN t = do
  token <- canViewImages t
  let canManage = canCreateImages token
  let ~(Just userToken) = t
  env <- asks $ getEnvFor DeploymentService
  let page = unpackPage pageN
  i@(PagedResponse { responseTotal=imagesTotal, responseObjects=images }) <- globalDecoder' $ defaultRetryClientC env (C.getPagedTemplates (Just page) userToken)
  jobserviceEnv <- asks $ getEnvFor JobserviceAPI
  usageData' <- mapM (\x -> (defaultRetryClientC jobserviceEnv . flip Jobservice.getImageUsage userToken . T.pack . configTemplateName) x >>= \x' -> pure $ fmap (configTemplateName x,) x') images
  let usageData = (M.fromList . map (fromRight undefined) . filter isRight) usageData'
  let hasNext = hasNextPages page i
  let totallyEmpty = page == 1 && imagesTotal == 0
  (\v -> baseTemplate token Nothing (Just "Образы") v Nothing) [shamlet|
<div .container>
  $if canManage
    <form .box.block action=/image/create method=GET>
      <div .field>
        <label .label> Название шаблона
        <div .control>
          <input .input type=text name="name">
      <div .field>
        <label .label> VMID шаблона (должен быть уникальным)
        <div .control>
          <input .input type=text name="id">
      <button .button.is-success.is-fullwidth> Создать
  $if totallyEmpty
    <h1 .title.is-3> Нет доступных образов!
  $else
    <h1 .title.is-3> Доступные образы
    <table .table.is-fullwidth>
      <thead>
        <tr>
          <th> Название образа
          <th> VMID
          <th> Кол-во использований
          <th>
      <tbody>
        $forall (ConfigTemplate { .. }) <- images
          <tr>
            <td> #{configTemplateName}
            <td> #{configTemplateID}
            <td>
              $case M.lookup configTemplateName usageData
                $of Nothing
                  0
                $of (Just arr)
                  $if arr /= []
                    #{imageUsageModalForm (length arr) arr}
                  $else
                    0
            <td>
              <a href=/image/#{configTemplateID}/delete> Удалить
    <nav .pagination.is-centered>
      <ul .pagination-list>
        $if page /= 1
          <li>
            <a .pagination-link href=/image/my?page=#{preEscapedToHtml $ page - 1}> #{page - 1}
        <li>
          <a .pagination-link.is-current> #{page}
        $if hasNext
          <li>
            <a .pagination-link href=/image/my?page=#{preEscapedToHtml $ page + 1}> #{page + 1}
|]

createImagePage :: Maybe Text -> Maybe Int -> Maybe BearerWrapper -> AppT Html
createImagePage (Just name) (Just id') t = do
  token <- requireToken' t
  let canManage = canCreateImages token
  if not canManage then sendJSONError err403 (JSONError "" "" Null) else do
    let ~(Just userToken) = t
    env <- asks $ getEnvFor DeploymentService
    createRes <- (defaultRetryClientC env (C.createTemplate (ConfigTemplate {configTemplateID=id', configTemplateName=T.unpack name}) userToken)) <&> tryDecodeError
    case createRes of
      (DecodedResult _)    -> tempRedirectTo "/image/my"
      (OtherError _)       -> sendJSONError err500 (JSONError "" "" Null)
      (DecodedError 400 _) -> do
        addMessageToSession token "Не удалось создать образ. Проверьте корректность и уникальность данных."
        tempRedirectTo "/image/my"
      (UndecodedError status _) -> throwError (ServerError {errBody="", errHTTPCode=status, errHeaders=[], errReasonPhrase=""})
      (DecodedError status _) -> throwError (ServerError {errBody="", errHTTPCode=status, errHeaders=[], errReasonPhrase=""})
createImagePage _ _ _ = tempRedirectTo "/image/my"

deleteImagePage :: Int -> Maybe BearerWrapper -> AppT Html
deleteImagePage id' t = do
  token <- requireToken' t
  let canManage = canCreateImages token
  let ~(Just userToken) = t
  if not canManage then sendJSONError err403 (JSONError "" "" Null) else do
    env <- asks $ getEnvFor DeploymentService
    _ <- globalDecoder' $ defaultRetryClientC env (C.deleteTemplate id' userToken)
    tempRedirectTo "/image/my"

copyDeploymentPage :: Int -> Maybe BearerWrapper -> AppT Html
copyDeploymentPage did t = do
  _ <- canCreateDeployments t
  let ~(Just userToken) = t
  env <- asks $ getEnvFor DeploymentService
  ts <- liftIO $ getUnixIntTime >>= formatUnixTimeLocal
  (DeploymentTemplate { .. }) <- globalDecoder' (defaultRetryClientC env $ C.getDeploymentTemplate did userToken)
  _ <- globalDecoder' (defaultRetryClientC env $ C.createDeploymentTemplate (DeploymentCreate {reqVMs=templateVMs, reqTitle=templateTitle <> " - копия [" <> T.pack ts <> "]", reqNetworks=templateNetworks, reqAvailableVMs=templateAvaiableVMs, reqSnapshotPolicy=templateSnapshotPolicy}) userToken)
  tempRedirectTo "/deployment/my"

deleteDeploymentPage :: Int -> Maybe BearerWrapper -> AppT Html
deleteDeploymentPage did t = do
  _ <- canCreateDeployments t
  let ~(Just userToken) = t
  env <- asks $ getEnvFor DeploymentService
  _ <- globalDecoder' (defaultRetryClientC env $ C.deleteDeploymentTemplate did userToken)
  tempRedirectTo "/deployment/my"


deploymentEditPage :: Int -> Maybe BearerWrapper -> AppT Html
deploymentEditPage tid t = do
  token <- canCreateDeployments t
  let ~(Just userToken) = t
  env <- asks $ getEnvFor DeploymentService
  templates <- iteratePagedResponse (\p -> globalDecoder' $ defaultRetryClientC env (C.getPagedTemplates (Just p) userToken))
  template <- globalDecoder' $ defaultRetryClientC env (C.getDeploymentTemplate tid userToken)
  let names = prettyEncode $ map configTemplateName templates
  let availableInterfaces = (LBS.unpack . encode) [E1000, E1000E, VIRTIO, VMXNET3]

  -- legacy fallback
  let declaredNets = map configNetworkName (templateNetworks template)
  let vmsNetworks = nub $ map configVMNetworkName $ foldMap (fromMaybe [] . configVMNetworks) (templateVMs template)
  let missingNetworks = map (\v -> SDNNetwork {configNetworkZone="", configNetworkVLANAware=Nothing, configNetworkSubnets=[], configNetworkName=v}) $ filter (`notElem` declaredNets) vmsNetworks


  let vmsEncoded = prettyEncode $ map (\(v, (Object objMap)) -> Object (KM.insert "available" (Bool $ (T.pack . configVMName) v `elem` templateAvaiableVMs template) objMap)) $ map (\x -> (x, toJSON x)) (templateVMs template)
  baseTemplate token Nothing (Just "Редактирование развертывания") genericDeploymentForm (Just $ h names availableInterfaces template vmsEncoded missingNetworks) where
    title' = T.replace "\"" "\\\""
    h names availableInterfaces template@(DeploymentTemplate { .. }) vms missingNetworks = [shamlet|
<script>
  ^{unwrapErrorFunction}
  document.addEventListener('alpine:init', () => {
    Alpine.data("formData", () => ({
      templates: #{preEscapedToMarkup names},
      title: "#{preEscapedText $ title' templateTitle}",
      vms: #{preEscapedToMarkup vms},
      snapshotPolicy: #{(preEscapedToMarkup . prettyEncode) templateSnapshotPolicy},
      addVM() { this.vms.push({clone_from: this.templates[0], available: true, networks: [], delay: 0, clean_networks: true, running: true, cores: 1, memory: 1024, cpu_limit: 1, name: "", storage: ""}) },
      deleteVM(i) { this.vms.splice(i, 1) },
      networks: #{preEscapedToMarkup $ prettyEncode (templateNetworks ++ missingNetworks)},
      removeENet(i) { this.networks.splice(i, 1) },
      moveVM(index, delta) {
        if (this.vms.length < 2 || index + delta < 0 || index + delta >= this.vms.length - 1) {
          return;
        }

        var d = this.vms.splice(index, 1)[0];
        this.vms.splice(index + delta, 0, d);
      },
      sendRequest() {
        var availableVMs = this.vms.filter(i => i.available).map(i => i.name);
        var processedNetworks = this.networks.map(i => i.type == 'sdn' ? { ...i, zone: '' } : i)
        var payload = JSON.stringify({title: this.title, availableVMs: availableVMs, networks: processedNetworks, vms: this.vms, snapshot: this.snapshotPolicy});
        fetch("/api/deployment/deployments/#{templateId}", {
          method: "PATCH",
          body: payload,
          headers: {
            'Content-Type': 'application/json'
          }
        }).then(r => {
          unwrapError(r, () => { window.location.href = "/deployment/my" }, (e) => this.addNotification(e))
        }).catch(err => {
          console.log(err);
        })
      }
    }))

    Alpine.data("diskForm", (vmData) => ({
      number: 0,
      allowedDiskTypes: ['ide', 'sata', 'scsi', 'virtio'],
      selectedType: "ide",
      size: "1G",
      storage: "",
      addDisk() { if (this.number >= 0 && this.size.length > 0 && this.storage.length > 0)
        { if (!vmData.disks.map(el => el.number).includes(this.number)) {
          vmData.disks.push({number: this.number, type: this.selectedType, size: this.size, storage: this.storage });
          this.number = 0;
          this.size = "1G";
          }
        }
      },
      removeDisk(index) { vmData.disks.splice(index, 1) }
    }))

    Alpine.data("netForm", (vmData, netIndex) => ({
      init() {
        if (vmData == undefined) { return; }
        if (vmData.networks[netIndex]['cloudinit_address'] == 'dhcp') {
          this.cloud_opts = 'dhcp'
          this.cloudOptsChange(undefined)
        } else if (vmData.networks[netIndex]['cloudinit_address'] != null) {
          this.cloud_opts = 'manual'
          this.cloudOptsChange(undefined)
        }
      },
      interfaces: #{preEscapedToMarkup availableInterfaces},
      netname: "",
      nettype: #{preEscapedToMarkup availableInterfaces}[0],
      cloud_opts: "",
      cloudOptsChange(event) {
        if (this.cloud_opts == "dhcp") {
           vmData.networks[netIndex]['cloudinit_address'] = 'dhcp'
           vmData.networks[netIndex]['cloudinit_gateway'] = null
        }
        if (this.cloud_opts == "" || this.cloud_opts == "manual") {
           if (vmData.networks[netIndex]['cloudinit_address'] == 'dhcp') {
              vmData.networks[netIndex]['cloudinit_address'] = null
           }
           if (this.cloud_opts == "") {
              vmData.networks[netIndex]['cloudinit_gateway'] = null
           }
        }
      },
      addNetwork(vm) { if (this.netname.length > 0) { vm.networks.push({name: this.netname, type: this.nettype, number: null, cloudinit_address: null, cloudinit_gateway: null}); this.nettype = this.interfaces[0]; } },
      removeNetwork(vm, index) { vm.networks.splice(index, 1) }
    }))
  })
|]

deploymentCreatePage :: Maybe BearerWrapper -> AppT Html
deploymentCreatePage t = do
  token <- canCreateDeployments t
  let ~(Just userToken) = t
  env <- asks $ getEnvFor DeploymentService
  templates <- iteratePagedResponse (\p -> globalDecoder' $ defaultRetryClientC env (C.getPagedTemplates (Just p) userToken))
  let names = prettyEncode $ map configTemplateName templates
  let availableInterfaces = (LBS.unpack . encode) [E1000, E1000E, VIRTIO, VMXNET3]
  baseTemplate token Nothing (Just "Создание развертывания") genericDeploymentForm (Just $ h names availableInterfaces) where
    h names availableInterfaces = [shamlet|
<script>
  ^{unwrapErrorFunction}
  document.addEventListener('alpine:init', () => {
    Alpine.data("formData", () => ({
      templates: #{preEscapedToMarkup names},
      title: "",
      vms: [],
      snapshotPolicy: {quota: 0, deleteOwned: false, useAny: false, deleteAny: false},
      addVM() { this.vms.push({clone_from: this.templates[0], available: true, networks: [], delay: 0, clean_networks: true, running: true, cores: 1, memory: 1024, cpu_limit: 1, name: "", storage: "", disks: []}) },
      deleteVM(i) { this.vms.splice(i, 1) },
      moveVM(index, delta) {
        if (this.vms.length < 2 || index + delta < 0 || index + delta >= this.vms.length - 1) {
          return;
        }

        var d = this.vms.splice(i, 1)[0];
        this.vms.splice(index + delta, 0, d);
      },
      networks: [],
      removeENet(i) { this.networks.splice(i, 1) },
      sendRequest() {
        var availableVMs = this.vms.filter(i => i.available).map(i => i.name);
        var payload = JSON.stringify({title: this.title, availableVMs: availableVMs, networks: this.networks, vms: this.vms, snapshot: this.snapshotPolicy});
        fetch("/api/deployment/deployments", {
          method: "POST",
          body: payload,
          headers: {
            'Content-Type': 'application/json'
          }
        }).then(r => {
          unwrapError(r, () => { window.location.href = "/deployment/my" }, (e) => this.addNotification(e))
        }).catch(err => {
          console.log(err);
        })
      }
    }))

    Alpine.data("diskForm", (vmData) => ({
      number: 0,
      allowedDiskTypes: ['ide', 'sata', 'scsi', 'virtio'],
      selectedType: "ide",
      size: "1G",
      storage: "",
      addDisk() { if (this.number >= 0 && this.size.length > 0 && this.storage.length > 0)
        { if (!vmData.disks.map(el => el.number).includes(this.number)) {
          vmData.disks.push({number: this.number, type: this.selectedType, size: this.size, storage: this.storage });
          this.number = 0;
          this.size = "1G";
          }
        }
      },
      removeDisk(index) { vmData.disks.splice(index, 1) }
    }))

    Alpine.data("netForm", (vmData, netIndex) => ({
      interfaces: #{preEscapedToMarkup availableInterfaces},
      netname: "",
      nettype: #{preEscapedToMarkup availableInterfaces}[0],
      cloud_opts: "",
      cloudOptsChange(event) {
        if (this.cloud_opts == "dhcp") {
           vmData.networks[netIndex]['cloudinit_address'] = 'dhcp'
           vmData.networks[netIndex]['cloudinit_gateway'] = null
        }
        if (this.cloud_opts == "" || this.cloud_opts == "manual") {
           vmData.networks[netIndex]['cloudinit_address'] = null
           vmData.networks[netIndex]['cloudinit_gateway'] = null
        }
      },
      addNetwork(vm) { if (this.netname.length > 0) { vm.networks.push({name: this.netname, type: this.nettype, number: null, cloudinit_address: null, cloudinit_gateway: null}); this.nettype = this.interfaces[0]; } },
      removeNetwork(vm, index) { vm.networks.splice(index, 1) }
    }))
  })
|]

noRights :: AppT Html
noRights = do
  pure $ headlessTemplate (Just "Ошибка!") body where
    body = [shamlet|
<section class="hero is-danger is-fullheight">
  <div class="hero-body">
    <div>
      <p class="title"> Ошибка доступа!
      <p class="subtitle"> У вас нет прав на выполнение данного действия.
|]

internalError :: AppT Html
internalError = do
  pure $ headlessTemplate (Just "Ошибка!") body where
    body = [shamlet|
<section class="hero is-danger is-fullheight">
  <div class="hero-body">
    <div>
      <p class="title"> Внутренняя ошибка!
      <p class="subtitle"> Обратитесь к системному администратору и попробуйте обновить страницу
|]

notFound :: AppT Html
notFound = do
  pure $ headlessTemplate (Just "Страница не найдена!") body where
    body = [shamlet|
<section class="hero is-danger is-fullheight">
  <div class="hero-body">
    <div>
      <p class="title"> Страница не найдена!
      <p class="subtitle"> Страница с данным адресом недоступна.
|]

vncPageFull :: Text -> Maybe BearerWrapper -> AppT Html
vncPageFull vmPort t = let
  body = [shamlet|
<div #app>
|]
  after = [shamlet|
<script src=/static/js/vnc.js>
|]
  head = [shamlet|
<link rel=stylesheet href=/static/css/vnc.css>
|]
  in do
  token <- requireToken' t
  let ~(Just userToken) = t
  deploymentEnv <- asks $ getEnvFor DeploymentService
  (PowerState vmOn) <- globalDecoder' $ defaultRetryClientC deploymentEnv (C.getVMPortPower vmPort userToken)
  unless vmOn $ addMessageToSession token "Виртуальная машина выключена. Включите ее на странице стенда, доступ на данной странице восстановится автоматически."
  vncTemplate token (Just head) (Just "VNC") body (Just after)

vncPage :: Text -> Maybe BearerWrapper -> AppT Html
vncPage vmPort t = let
  vmWidgets = [shamlet|
<div .columns.is-multiline>
  <div .column.is-6>
    <div .block x-data="{ networks: null }" x-init="fetch('/api/deployment/vm/#{vmPort}/networks').then(r => r.json()).then(d => networks = d)">
      <template x-if="networks">
        <div .columns.is-centered>
          <div .column.is-half>
            <table .table.is-fullwidth>
              <thead>
                <tr>
                  <th> MAC-адрес
                  <th> Название сети
              <tbody>
                <template x-for="mac in Object.keys(networks)">
                  <tr>
                    <td x-text="mac">
                    <td x-text="networks[mac]">
  <div .column.is-6>
    <div .block x-data="snapshotForm('#{vmPort}')">
      <div .modal *{rollbackModal}>
        <div .modal-background>
        <div .modal-content>
          <div .card.p-3>
            <p .pb-1>
              Откатить снапшот
              <span x-text="active_snap">
              ?
            <div .columns.is-fullwidth>
              <div .is-6.column>
                <button @click="show_rollback = false" .button.is-fullwidth> Отменить
              <div .is-6.column>
                <button .is-warning.button.is-fullwidth @click="rollback(active_snap)"> Откатить
          <button @click="show_rollback = false" .modal-close.is-large aria-label=close>
      <div .modal *{deleteModal}>
        <div .modal-background>
        <div .modal-content>
          <div .card.p-3>
            <p .pb-1>
              Удалить снапшот
              <span x-text="active_snap">
              ?
            <div .columns.is-fullwidth>
              <div .is-6.column>
                <button @click="show_delete = false" .button.is-fullwidth> Отменить
              <div .is-6.column>
                <button .is-danger.button.is-fullwidth @click="deleteSnap(active_snap)"> Удалить
          <button @click="show_delete = false" .modal-close.is-large aria-label=close>
      <template x-if="snaps == null">
        <p> Загружается список снапшотов
      <template x-if="snaps">
        <table .table>
          <thead>
            <tr>
              <th> Снапшот
              <th>
                <button @click="createSnap" .button> Создать снапшот
              <th>
                <button @click="init" .button> Обновить
          <tbody>
            <template x-for="snap in snaps">
              <tr>
                <td x-text="snap.name">
                <td>
                  <button @click="active_snap=snap.name;show_rollback=true" .button.is-outlined.is-warning> Откатить
                <td>
                  <button @click="active_snap=snap.name;show_delete=true" .button.is-outlined.is-danger> Удалить
            <template x-if="snaps != null && snaps.length == 0">
              <tr>
                <td> Нет доступных снапшотов!
|]
  body = [shamlet|
<div .block>
  <div .container>
    <div #app>
^{vmWidgets}
|]
  deleteModal = [(":class", "show_delete ? 'is-active' : ''")] :: [(String, String)]
  rollbackModal = [(":class", "show_rollback ? 'is-active' : ''")] :: [(String, String)]
  after = [shamlet|
<script src=/static/js/vnc.js>
<script>
  ^{unwrapErrorFunction}
  document.addEventListener('alpine:init', () => {
    Alpine.data("snapshotForm", (vmPort) => ({
      snaps: null,
      show_delete: false,
      show_rollback: false,
      active_snap: '',
      init() {
        fetch("/api/deployment/vm/" + vmPort + "/snapshot/list").then(r => {
          unwrapError(r, () => { r.json().then(resp => { this.snaps = resp }) }, (e) => this.addNotification(e))
        }).catch(err => {
          console.log(err);
        })
      },
      rollback(snapName) {
        fetch("/api/deployment/vm/" + vmPort + "/snapshot/rollback?name=" + encodeURIComponent(snapName)).then(r => {
          unwrapError(r, () => { r.json().then(_ => this.addNotification("Запрос на откатывание ВМ отправлен. Ожидайте выполнения в течение 30 секунд."))}, (e) => this.addNotification(e));
          this.show_rollback = false
        }).catch(err => {
          console.log(err);
        })
      },
      deleteSnap(snapName) {
        fetch("/api/deployment/vm/" + vmPort + "/snapshot?name=" + encodeURIComponent(snapName), {method: 'DELETE'}).then(r => {
          unwrapError(r, () => { r.json().then(_ => this.addNotification("Запрос на удаление снапшота отправлен. Ожидайте выполнения в течение 30 секунд."))}, (e) => this.addNotification(e));
          this.show_delete=false
        }).catch(err => {
          console.log(err);
        })
      },
      createSnap() {
        fetch("/api/deployment/vm/" + vmPort + "/snapshot").then(r => {
          unwrapError(r, () => { r.json().then(_ => this.addNotification("Запрос на создание снапшота отправлен. Ожидайте выполнения в течение 30 секунд."))}, (e) => this.addNotification(e))
        }).catch(err => {
          console.log(err);
        })
      }
    }))
  })
|]

  head = [shamlet|
<link rel=stylesheet href=/static/css/vnc.css>
|]
  in do
  token <- requireToken' t
  let ~(Just userToken) = t
  deploymentEnv <- asks $ getEnvFor DeploymentService
  (PowerState vmOn) <- globalDecoder' $ defaultRetryClientC deploymentEnv (C.getVMPortPower vmPort userToken)
  unless vmOn $ addMessageToSession token "Виртуальная машина выключена. Включите ее на странице стенда, доступ на данной странице восстановится автоматически."
  baseTemplate token (Just head) (Just "VNC") body (Just after)

deploymentListPage :: Maybe Int -> Maybe BearerWrapper -> AppT Html
deploymentListPage pageN t = do
  ~token@(ActiveToken { .. }) <- canCreateDeployments t
  let ~(Just userToken) = t
  let page = unpackPage pageN
  authEnv <- asks $ getEnvFor AuthService
  allRoles <- withTokenVariable' $ \token' -> do
    globalDecoder' $ defaultRetryClientC authEnv (Auth.getAllGroups (BearerWrapper token'))
  let roleNames = map groupName allRoles
  env <- asks $ getEnvFor DeploymentService
  d@(PagedResponse {responseTotal=totalDeployments, responseObjects=deployments}) <- globalDecoder' $ defaultRetryClientC env (C.getPagedDeploymentTemplates (Just page) userToken)
  let foreignOwners = map templateOwner $ filter (\t -> (Just . templateOwner) t /= tokenUUID) deployments
  foreignOwnersMap <- gatherUsers foreignOwners
  let hasNext = hasNextPages page d
  let totallyEmpty = page == 1 && totalDeployments == 0

  let hiddenModal = [(":class", "hidden_show ? 'is-active' : ''")] :: [(String, String)]
  (\v -> baseTemplate token Nothing (Just "Развертывания") v (Just $ genericGroupActionFormData (if null allRoles then Nothing else (Just $ head allRoles)))) [shamlet|
<div .container>
  $if totallyEmpty
    <h1 .title.is-3> Нет доступных развертываний!
  $else
    <h1 .title.is-3> Доступные развертывания
    <div .columns.is-multiline>
    $forall (DeploymentTemplate { .. }) <- deployments
      <div .column x-data="{hidden_show:false}">
        <div .card>
          <div .modal *{hiddenModal}>
            <div .modal-background>
            <div .modal-content>
              <div .card.p-5>
                <table .table.is-fullwidth>
                  <thead>
                    <tr>
                      <th> Группа
                      <th>
                  <tbody>
                    $if (not . null) templateHiddenFor
                      $forall group <- templateHiddenFor
                        <tr>
                          <td style="width:80%"> #{group}
                          <td>
                            <button .button.mx-auto @click="fetch('/api/deployment/deployments/#{templateId}/hide?group=#{encodeText group}').then(_ => window.location.reload())"> Показать
                    $forall group <- roleNames
                      $if not (elem group templateHiddenFor)
                        <tr>
                          <td .is-fullwidth> #{group}
                          <td>
                            <button .button @click="fetch('/api/deployment/deployments/#{templateId}/hide?group=#{encodeText group}').then(_ => window.location.reload())"> Скрыть
            <button @click="hidden_show = false" .modal-close.is-large aria-label=close>
          <header .card-header>
            <p .card-header-title>
              #{templateTitle}
              $if tokenUUID /= Just templateOwner
                $case M.lookup templateOwner foreignOwnersMap
                  $of Nothing
                    <span>: Ошибка определения пользователя
                  $of (Just (BriefUser { .. }))
                    <span>: #{ fromMaybe "-" userFirstName } #{ fromMaybe "-" userLastName }
            <div .dropdown>
              <div .dropdown-trigger>
                <button .button aria-haspopup="true" aria-controls="dropdown-menu">
                  <span> Действия
              <div .dropdown-menu role="menu">
                <div .dropdown-content>
                  <button .dropdown-item x-on:click="hidden_show=true"> Скрыть
                  <a .dropdown-item href=/deployment/#{templateId}/copy> Создать копию
                  <a .dropdown-item href=/deployment/#{templateId}/delete> Удалить
          <div .card-content>
            <p> Состав развертывания
            <table .table.is-fullwidth>
              <thead>
                <tr>
                  <th> Название VM
                  <th> Память/ядер
                  <th> Родительский шаблон
                  <th> Подключенные сети
                  <th> Доступна пользователю
              <tbody>
                $forall vm <- templateVMs
                  $case vm
                    $of (TemplatedConfigVM { .. })
                      <tr>
                        <td> #{configVMName}
                        <td> #{fromMaybe "-" (fmap show configVMMemory)} / #{fromMaybe "-" (fmap show configVMCores)}
                        <td> #{configVMParentTemplate}
                        <td> #{intercalate ", " (map configVMNetworkName (fromMaybe [] configVMNetworks))}
                        <td>
                          $if elem (T.pack configVMName) templateAvaiableVMs
                            Да
                          $else
                            Нет
            <p> Развертывание
            ^{genericGroupActionForm templateId allRoles}
          <footer .card-footer>
            <a .card-footer-item href=/deployment/#{templateId}/instances> Стенды
            <a .card-footer-item href=/deployment/#{templateId}/edit> Редактировать
    <nav .pagination.is-centered>
      <ul .pagination-list>
        $if page /= 1
          <li>
            <a .pagination-link href=/deployment/my?page=#{preEscapedToHtml $ page - 1}> #{page - 1}
        <li>
          <a .pagination-link.is-current> #{page}
        $if hasNext
          <li>
            <a .pagination-link href=/deployment/my?page=#{preEscapedToHtml $ page + 1}> #{page + 1}
|]

indexPage :: Maybe BearerWrapper -> Maybe Int -> AppT Html
indexPage t pageN = let
  anonBody = [shamlet|
<div .container>
  <h1 .title.is-3> Привет, $userName!
  <p> Войди, чтобы получить доступ к лабам
      |]
  in do
  token <- lookupToken' t
  case token of
    InactiveToken -> do
      baseTemplate token Nothing (Just "Index") anonBody Nothing
    (ActiveToken { .. }) -> do
      let page = unpackPage pageN
      deploymentEnv <- asks $ getEnvFor DeploymentService
      let ~(Just userToken) = t
      instanceResp@(PagedResponse {responseTotal=instanceTotal, responseObjects=instances}) <- globalDecoder' $ defaultRetryClientC deploymentEnv $ C.getMyTemplateInstances (Just page) userToken
      let hasNext = hasNextPages page instanceResp
      let totallyEmpty = page == 1 && instanceTotal == 0
      (\v -> baseTemplate token Nothing (Just "Index") v Nothing) [shamlet|
<div .container>
  $if totallyEmpty
    <h1 .title.is-3> Доступных лаб нет!
  $else
    <h1 .title.is-3> Доступные стенды
    <div .columns.is-multiline>
    $forall (DeploymentInstanceBrief { .. }) <- instances
      <div .column>
        <div .card>
          <header .card-header>
            <p .card-header-title>
              #{ briefDeploymentTitle }
          <footer .card-footer>
            <a .card-footer-item href=/instance/#{briefDeploymentId}> Открыть
    <nav .pagination.is-centered>
      <ul .pagination-list>
        $if page /= 1
          <li>
            <a .pagination-link href=/?page=#{preEscapedToHtml $ page - 1}> #{page - 1}
        <li>
          <a .pagination-link.is-current> #{page}
        $if hasNext
          <li>
            <a .pagination-link href=/?page=#{preEscapedToHtml $ page + 1}> #{page + 1}
|]

instanceSchemaPage :: Text -> Maybe BearerWrapper -> AppT Html
instanceSchemaPage dID t = do
  token <- requireToken' t
  let ~(Just userToken) = t
  krokiEnv <- asks $ getEnvFor KrokiProxy
  topologyReq <- defaultRetryClientC krokiEnv (renderInstanceDiagram dID userToken)
  let head' = [shamlet|
<style>
  .svg__container svg {
    width: inherit;
    max-width: max(500px, 85%);
  }

  .svg__container {
    display: flex;
    justify-content: center;
    align-items: center;
  }
|]
  let body = [shamlet|
<div .container>
  <a .button href="/instance/#{dID}"> Вернуться назад
  $case topologyReq
    $of (Right svg)
      <div .svg__container>
        #{preEscapedToMarkup svg}
    $of Left _
      <p> Ошибка рендеринга!
|]
  baseTemplate token (Just head') (Just "Топология") body Nothing

getUserName :: Text -> AppT (Maybe BriefUser)
getUserName uid = do
  e <- asks $ getEnvFor AuthService
  r <- withTokenVariable' $ \token -> do
    defaultRetryClientC e $ Auth.getUserBriefInfo uid (BearerWrapper token)
  case r of
    (Left _)  -> pure Nothing
    (Right u) -> pure (Just u)

instancePowerPage :: Text -> Maybe BearerWrapper -> Maybe Int -> AppT Html
instancePowerPage dID t powerFlag' = do
  deploymentEnv <- asks $ getEnvFor DeploymentService
  token <- requireToken' t
  let (ActiveToken { .. }) = token
  let ~(Just userToken) = t
  (DeploymentInstance { .. }) <- globalDecoder' $ defaultRetryClientC deploymentEnv (C.getDeploymentInstance dID userToken)
  let powerFlag = fromMaybe 0 powerFlag' == 1
  let targetVMs = map fst . filter ((/= powerFlag) . snd) $ M.toList instanceVMPower
  let targetPorts = mapMaybe (`M.lookup` instanceVMLinks) targetVMs
  _ <- globalDecoder' $ defaultRetryClientC deploymentEnv $ mapM (`C.switchVMPortPower` userToken) targetPorts
  tempRedirectTo $ "/instance/" <> T.unpack dID

instancePage :: Text -> Maybe BearerWrapper -> Maybe Text -> AppT Html
instancePage dID t (Just vmPort) = do
  _ <- requireToken' t
  let ~(Just userToken) = t
  deploymentEnv <- asks $ getEnvFor DeploymentService
  _ <- globalDecoder' $ defaultRetryClientC deploymentEnv (C.switchVMPortPower vmPort userToken)
  tempRedirectTo $ "/instance/" <> T.unpack dID
instancePage dID t Nothing = do
  deploymentEnv <- asks $ getEnvFor DeploymentService
  token <- requireToken' t
  let (ActiveToken { .. }) = token
  let ~(Just userToken) = t
  d@(DeploymentInstance { instanceDeployConfig = unsafeConfig,.. }) <- globalDecoder' $ defaultRetryClientC deploymentEnv (C.getDeploymentInstance dID userToken)
  let instanceDeployConfig = fmap (\c@(DeployConfig { deployParameters = p, deployAgent = a }) -> c { deployParameters = p { deployToken = Nothing }, deployAgent = fmap (\agent -> agent { configAgentToken = "" }) a }) unsafeConfig

  let showText = "open ? 'Закрыть' : 'Открыть'" :: String
  displayName <- if Just instanceUser == tokenUUID then pure Nothing else getUserName instanceUser

  let head' = [shamlet|
<style>
  .svg__container svg {
    width: inherit;
    max-width: max(60%, 500px);
    margin: auto;
  }

  .svg__container {
    display: flex;
    justify-content: center;
    align-items: center;
  }
|]
  case instanceState of
    Deployed -> do
      let getPowerUrl key = "/instance/" <> T.unpack dID <> "?power=" <> key

      krokiEnv <- asks $ getEnvFor KrokiProxy
      topologyReq <- defaultRetryClientC krokiEnv (renderInstanceDiagram dID userToken)
      (\v -> baseTemplate token (Just head') (Just . T.unpack $ instanceTitle) v Nothing) [shamlet|
<div .container>
  <h1 .title.is-3>
    #{instanceTitle}
    $case displayName
      $of Just (BriefUser { .. })
        : #{fromMaybe "-" userFirstName} #{fromMaybe "-" userLastName}
      $of Nothing
  $case topologyReq
    $of (Right svg)
      <div x-data="{ open: false }">
        <div .is-flex.is-flex-direction-row>
          <div .pr-5>
            <h2 .subtitle.is-4> Автоматическая топология
          <div .is-flex.is-flex-direction-row>
            <button .button @click="open = ! open" x-text=#{showText}>
            <a target=_blank .button href=/instance/#{dID}/schema> В новом окне
        <div .is-max-tablet.container.svg__container x-show="open">
          #{preEscapedToMarkup svg}
    $of Left _
  <div .is-flex.is-flex-direction-row.is-flex-wrap-wrap.is-align-items-center>
    <div .mr-2>
      <a .button.is-danger.is-outlined href=/instance/#{dID}/power?power=0> Выключить все
    <div .ml-2>
      <a .button.is-success.is-outlined href=/instance/#{dID}/power?power=1> Включить все
  <table .table.is-fullwidth>
    <thead>
      <tr>
        <th> Имя виртуальной машины
        <th> Ссылка подключения
        <th> Состояние питания
        <th>
    <tbody>
      $forall (key, value) <- M.toList instanceVMLinks
        <tr>
          <td> #{key}
          <td>
            <a href=/vnc/#{value}> подключиться
            <span> /
            <a href=/vnc/#{value}/full> полный экран
          <td>
            $case M.lookup key instanceVMPower
              $of (Just True)
                включена
              $of (Just False)
                выключена
              $of Nothing
                неизвестно
          <td>
            $with powerUrl <- getPowerUrl (T.unpack value)
              <a .button href=#{powerUrl}>
                $case M.lookup key instanceVMPower
                  $of (Just True)
                    Выключить
                  $of _
                    Включить
  $case instanceDeployConfig
    $of (Just deployConfig)
      <div x-data="{ open: false }">
        <div .is-flex.is-flex-direction-row>
          <div .pr-5>
            <h2 .subtitle.is-4> Отладочная информация
              <i .pl-1>
                (видна администратору)
          <div>
            <button .button @click="open = ! open" x-text=#{showText}>
        <div x-show="open"> #{ LBS.unpack $ encodePretty deployConfig}
    $of Nothing
  $if (not . null) instanceLogs
    <div x-data="{ open: false }">
      <div .is-flex.is-flex-direction-row>
        <div .pr-5>
          <h2 .subtitle.is-4> Логи развертывания
            <i .pl-1>
              (видны администратору)
        <div>
          <button .button @click="open = ! open" x-text=#{showText}>
      <div x-show="open">
        <ul>
          $forall logString <- instanceLogs
            $forall line <- T.splitOn "\n" logString
              <li> #{line}
|]
    _anyOther -> do
      (\v -> baseTemplate token Nothing (Just . T.unpack $ instanceTitle) v Nothing) [shamlet|
<div .container>
  <h1 .title.is-3> #{instanceTitle}
    $case displayName
      $of Just (BriefUser { .. })
        : #{fromMaybe "-" userFirstName} #{fromMaybe "-" userLastName}
      $of Nothing
  <article .message.is-info>
    <div .message-header>
      Ой!
    <div .message-body>
      Скоро тут будет ваш стенд. А пока ничего нет, попробуйте обновить страницу позже или обратиться к преподавателю.
  $case instanceDeployConfig
    $of (Just deployConfig)
      <div x-data="{ open: false }">
        <div .is-flex.is-flex-direction-row>
          <div .pr-5>
            <h2 .subtitle.is-4> Отладочная информация
              <i .pl-1>
                (видна администратору)
          <div>
            <button .button @click="open = ! open" x-text=#{showText}>
        <div x-show="open"> #{ LBS.unpack $ encodePretty deployConfig}
    $of Nothing
  $if (not . null) instanceLogs
    <div x-data="{ open: false }">
      <div .is-flex.is-flex-direction-row>
        <div .pr-5>
          <h2 .subtitle.is-4> Логи развертывания
            <i .pl-1>
              (видны администратору)
        <div>
          <button .button @click="open = ! open" x-text=#{showText}>
      <div x-show="open">
        <ul>
          $forall logString <- instanceLogs
            $forall line <- T.splitOn "\n" logString
              <li> #{line}
|]
