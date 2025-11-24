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
{-# LANGUAGE QuasiQuotes #-}
module Templates.Components
  ( genericDeploymentForm
  , genericGroupActionFormData
  , genericGroupActionForm
  , genericInstanceActionFormData
  , genericInstanceActionForm
  , genericLargeSelectForm
  , unwrapErrorFunction
  ) where

import           Api.Keycloak.Models.Group
import           Data.Text                 (Text)
import qualified Data.Text                 as T
import           Text.Blaze.Html
import           Text.Hamlet

unwrapErrorFunction :: Html
unwrapErrorFunction = [shamlet|
const unwrapError = (r, success, error) => {
  if (r.ok) {
    success()
  } else {
    r.json().then(resp => {
      if (resp.context) {
        if (resp.context.message) {
          error(resp.context.message)
          return
        }
      }
      error(resp.error)
    }).catch(err => { error(err) })
  }
}
|]

genericInstanceActionFormData :: Html
genericInstanceActionFormData = [shamlet|
<script>
  document.addEventListener('alpine:init', () => {
    Alpine.data("instanceActionFormData", (instanceId) => ({
      instanceId: instanceId,
      action: "makesnap",
      snapname: "",
      sendRequest() {
        if (this.snapname.length > 0 && (this.action == "makesnap" || this.action == "delsnap" || this.action == "rollback")) {
          let url = "/api/deployment/instances/" + instanceId + "/snapshot?snapname=" + encodeURIComponent(this.snapname) + (this.action == "delsnap" ? "&delete" : "") + (this.action == "rollback" ? "&rollback" : "")
          fetch(url).then(r => {
            if (r.ok) {
              location.reload();
            } else {
              return r.json().then(resp => {throw new Error(resp.error)})
            }
          }).catch(err => {
            alert("Ошибка: " + err)
            console.log(err);
          });
        }
      }
    }))
  })
|]

genericGroupActionFormData :: Maybe FoundGroup -> Html
genericGroupActionFormData group = [shamlet|
<script>
  document.addEventListener('alpine:init', () => {
    Alpine.data("groupDeploymentFormData", (deploymentId) => ({
      deploymentId: deploymentId,
      action: "deploy",
      group: "#{preEscapedToMarkup defaultGroup}",
      snapname: "",
      sendRequest() {
        if (this.action == "deploy" || this.action == "destroy") {
          let url = "/api/deployment/deployments/" + deploymentId + "/" + this.action + "/group?group=" + encodeURIComponent(this.group)
          fetch(url).then(r => {
            if (r.ok) {
              location.reload();
            } else {
              return r.json().then(resp => {throw new Error(resp.error)})
            }
          }).catch(err => {
            alert("Ошибка: " + err)
            console.log(err);
          });
        }
        if (this.action == "turnon" || this.action == "turnoff") {
          let url = "/api/deployment/deployments/" + deploymentId + "/power/group?group=" + encodeURIComponent(this.group) + (this.action == "turnon" ? "&on" : "")
          fetch(url).then(r => {
            if (r.ok) {
              location.reload();
            } else {
              return r.json().then(resp => {throw new Error(resp.error)})
            }
          }).catch(err => {
            alert("Ошибка: " + err)
            console.log(err);
          });
        }
        if (this.snapname.length > 0 && (this.action == "makesnap" || this.action == "delsnap" || this.action == "rollback")) {
          let url = "/api/deployment/deployments/" + deploymentId + "/snapshot/group?group=" + encodeURIComponent(this.group) + "&snapname=" + encodeURIComponent(this.snapname) + (this.action == "delsnap" ? "&delete" : "") + (this.action == "rollback" ? "&rollback" : "")
          fetch(url).then(r => {
            if (r.ok) {
              location.reload();
            } else {
              return r.json().then(resp => {throw new Error(resp.error)})
            }
          }).catch(err => {
            alert("Ошибка: " + err)
            console.log(err);
          });
        }
      }
    }))
  })
|] where
  defaultGroup = case group of
    Nothing                                        -> ""
    (Just (FoundGroup { groupName = groupName' })) -> T.unpack groupName'

genericInstanceActionForm :: Text -> Html
genericInstanceActionForm instanceKey = [shamlet|
<form .form @submit.prevent="" x-data="instanceActionFormData('#{preEscapedToMarkup instanceKey}')">
  <label .label> Выберите действие
  <div .control>
    <div .select>
      <select x-model="action">
        <option disabled> Выберите вариант
        <option value=makesnap> Сделать снапшот
        <option value=delsnap> Удалить снапшот
        <option value=rollback> Откатить стенды
  <template *{[("x-if", "action == 'makesnap' || action == 'delsnap' || action == 'rollback'")]}>
    <div>
      <label .label> Название снапшота
      <div .control>
        <input .input type=text x-model="snapname">
  <button .button.is-fullwidth @click="sendRequest"> Выполнить
|]

genericGroupActionForm :: Int -> [FoundGroup] -> Html
genericGroupActionForm templateId groups = [shamlet|
<form .form @submit.prevent="" x-data="groupDeploymentFormData(#{preEscapedToMarkup templateId})">
  <label .label> Целевая группа Keycloak
  <div .control>
    ^{genericLargeSelectForm "group" (map groupName groups)}
  <label .label> Выберите действие
  <div .control>
    <div .select>
      <select x-model="action">
        <option disabled> Выберите вариант
        <option value=deploy> Создать стенд
        <option value=destroy> Удалить стенд
        <option value=turnoff> Выключить стенд
        <option value=turnon> Включить стенд
        <option value=makesnap> Сделать снапшот
        <option value=delsnap> Удалить снапшот
        <option value=rollback> Откатить стенды
  <template *{[("x-if", "action == 'makesnap' || action == 'delsnap' || action == 'rollback'")]}>
    <div>
      <label .label> Название снапшота
      <div .control>
        <input .input type=text x-model="snapname">
  <button .button.is-fullwidth @click="sendRequest"> Выполнить
|]


genericLargeSelectForm :: String -> [Text] -> Html
genericLargeSelectForm bindTo values = let
  variantValues v = [("@click", bindTo <> "=\"" <> T.unpack v <> "\"; showed = false")]
  modalValues = [(":class", "showed ? 'is-active' : ''")]
  in [shamlet|
<div x-data="{ showed: false }">
  <div .control.is-fullwidth>
    <input .input.is-clickable type=text placeholder="Нажмите для выбора" readonly x-model=#{preEscapedToMarkup bindTo} @click="showed = true">
  <div .modal *{modalValues}>
    <div .modal-background>
    <div .modal-content>
      <div .card>
        $forall v <- values
          <button .is-meduim.is-fullwidth.button.py-2.my-2 *{variantValues v}> #{v}
    <button @click="showed = false" .modal-close.is-large aria-label=close>
|]

genericDeploymentForm = let
  indexKey :: [(String, String)]
  indexKey = [(":key", "index")]

  netIndexKey :: [(String, String)]
  netIndexKey = [(":key", "netIndex")]

  netSelectBind :: [(String, String)]
  netSelectBind = [(":selected", "vms[index]['networks'][netIndex]['type'] == avtype")]

  netNumberBind :: [(String, String)]
  netNumberBind = [(":selected", "vms[index]['networks'][netIndex]['number'] == i - 1")]

  templateBind :: [(String, String)]
  templateBind = [(":selected", "vms[index]['clone_from'] == template")]
  in [shamlet|
<div .container x-data>
  <form .form.is-fullwidth x-data="formData" @submit.prevent="">
    <div .control>
      <label .label> Имя стенда
      <input .input type=text x-model="title">
    <template x-for="(obj, index) in vms" *{indexKey}>
      <template x-if="vms[index]">
        <div .box>
          <div .field>
            <label .label> Название VM
            <div .control>
              <input .input type="text" x-model="vms[index]['name']">
          <div .field>
            <label .label> Клонировать из
            <div .control>
              <div .select>
                <select x-model="vms[index]['clone_from']">
                  <option value="" disabled> Выберите шаблон
                  <template x-for="template in templates">
                    <option x-text="template" *{templateBind}>
          <div .field>
            <label .label> Время ожидания после включения (в секундах)
            <div .control>
              <input .input type=number x-model.number="vms[index]['delay']">
          <div .field>
            <label .label> Кол-во ядер
            <div .control>
              <input .input type=number x-model.number="vms[index]['cores']">
          <div .field>
            <label .label> Кол-во ОЗУ (в МБ)
            <div .control>
              <input .input type=number x-model.number="vms[index]['memory']">
          <div .field>
            <label .label> Лимит нагрузки CPU (в ядрах)
            <div .control>
              <input .input type=number step=0.1 x-model.number="vms[index]['cpu_limit']">
          <div .field>
            <label .label> Хранилище для копирования
            <div .control>
              <input .input type=text x-model="vms[index]['storage']">
            <p .help> При пустом значении выполняется Linked Clone
          <div .control>
            <label .checkbox>
              <input .checkbox type=checkbox x-model="vms[index]['available']">
              Доступна пользователю
          <div .control>
            <label .checkbox>
              <input .checkbox type=checkbox x-model="vms[index]['running']">
              Включить VM при развертывании
          <div .field>
            <label .label> (cloud-init) Логин пользователя
            <div .control>
              <input .input type=text x-model="vms[index]['cloudinit_user']">
            <p .help> Опциальное поле, требует поддержки cloudinit
          <div .field>
            <label .label> (cloud-init) Пароль пользователя
            <div .control>
              <input .input type=text x-model="vms[index]['cloudinit_password']">
            <p .help> Опциальное поле, требует поддержки cloudinit
          <div .field>
            <label .label> (cloud-init) DNS-резолвер
            <div .control>
              <input .input type=text x-model="vms[index]['cloudinit_dns']">
            <p .help> Опциальное поле, требует поддержки cloudinit
          <div .field>
            <label .label> (cloud-init) SSH ключи
            <div .control>
              <textarea .textarea placeholder="Публичные SSH-ключи" rows=5 x-model="vms[index]['cloudinit_sshkeys']">
            <p .help> Опциальное поле, требует поддержки cloudinit
          <p .label> Подключение дополнительных дисков
          <div x-data="diskForm(obj)">
            <div .is-flex.is-flex-direction-row.is-align-items-center.is-fullwidth>
              <input .input type=number x-model.number="number" placeholder="Номер диска">
              <div .select>
                <select x-model="selectedType">
                  <template x-for="avtype in allowedDiskTypes">
                    <option x-text="avtype">
              <input .input type=text x-model="size" placeholder="Размер диска">
              <input .input type=text x-model="storage" placeholder="Целевое хранилище">
            <button .button @click="addDisk"> Добавить диск
            <p .label x-show="obj.disks.length > 0"> Добавленные диски
            <template x-for="(diskData, diskIndex) in vms[index]['disks']">
              <div .is-flex.is-flex-direction-row.is-align-items-center.is-fullwidth>
                <div .is-size-5>
                  <span x-text="diskData.type">
                  <span x-text="diskData.number">
                  <span> размером
                  <span x-text="diskData.size">
                  <span> на хранилище
                  <span x-text="diskData.storage">
                <button .button.is-danger.ml-5 @click="removeDisk(diskIndex)"> Удалить
          <p .label> Добавление сетей
          <div .is-flex.is-flex-direction-row.is-align-items-center.is-fullwidth x-data="netForm(undefined, undefined)">
            <input .input type="text" x-model="netname">
            <div .select>
              <select x-model="nettype">
                <template x-for="avtype in interfaces">
                  <option x-text="avtype">
            <button .button @click="addNetwork(vms[index])"> Подключить
          <template x-for="(netObj, netIndex) in vms[index]['networks']">
            <div x-data="netForm(vms[index], netIndex)">
              <p .label> Сеть <span x-text="netObj['name']">
              <div .is-flex.is-flex-direction-row.is-align-items-center.is-fullwidth>
                <input .input type="text" x-model="vms[index]['networks'][netIndex]['name']">
                <div .select>
                  <select x-model.number="vms[index]['networks'][netIndex]['number']">
                    <option value=""> -
                    <template x-for="i in 33">
                      <option x-text="i - 1" *{netNumberBind}>
                <div .select>
                  <select x-model="vms[index]['networks'][netIndex]['type']">
                    <template x-for="avtype in interfaces">
                      <option x-text="avtype" *{netSelectBind}>
                <div .select>
                  <select x-model="cloud_opts" x-on:change="cloudOptsChange">
                    <option value=""> Не устанавливать адрес
                    <option value="dhcp"> DHCP
                    <option value="manual"> Ручной адрес
                <button .button @click="removeNetwork(vms[index], netObj)"> Удалить
              <template x-if="cloud_opts == 'manual' && vms[index]['networks'][netIndex]['number'] != null">
                <div .is-flex.is-flex-direction-row.is-align-items-center.is-fullwidth>
                  <input .input type="text" placeholder="IP-адрес" x-model.string="vms[index]['networks'][netIndex]['cloudinit_address']" minlength="7">
                  <input .input type="text" placeholder="Шлюз" x-model.string="vms[index]['networks'][netIndex]['cloudinit_gateway']" minlength="7">
          <div .is-flex.is-flex-direction-row.is-align-items-center>
            <div .p-3>
              <button .button.is-danger @click="deleteVM(index)"> Удалить VM
            <div .p-3>
              <button .button @click="moveVM(index, -1)"> Передвинуть выше
            <div .p-3>
              <button .button @click="moveVM(index, 1)"> Передвинуть ниже
    <div .block>
      <button .button.is-fullwidth @click="addVM()"> Добавить ВМ
    <div .block x-data="{input: ''}">
      <h2 .subtitle.is-5> Список существующих сетей
      <p> Такие сети не создаются, а используют bridge с тем же именем.
      <div .control>
        <label .label> Имя сети
        <input .input type="text" x-model="input">
      <button .button.is-fullwidth @click="if (input.length > 0 && !existingNetworks.includes(input)) { existingNetworks.push(input); input = '' }"}> Добавить
      <template x-for="(net, netIndex) in existingNetworks" *{netIndexKey}>
        <div .is-flex.is-flex-direction-row.is-align-items-center.is-fullwidth>
          <p .pr-5 x-text="net">
          <button .button.is-danger @click="removeENet(netIndex)"> Удалить
    <button .button.is-success.is-fullwidth @click="sendRequest"> Создать стенд
|]
