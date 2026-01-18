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
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
module Templates.Base where

import           Api.Keycloak.Models.Introspect
import           Config
import           Control.Concurrent.STM         (atomically)
import           Control.Concurrent.STM.TVar
import           Control.Monad.IO.Class
import           Control.Monad.Reader
import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8     as LBS
import qualified Data.Map                       as M
import           Data.Maybe
import           Data.Text                      (Text)
import qualified Data.Text                      as T
import qualified Data.Text.Encoding             as T
import           Models.JSONError
import           Roles
import           Text.Blaze.Html
import           Text.Hamlet
import           Text.Shakespeare

badRequestTemplate :: JSONError -> Html
badRequestTemplate (JSONError { .. }) = headlessTemplate (Just "Неверный запрос") [shamlet|
<section class="hero is-warning is-fullheight">
  <div class="hero-body">
    <div x-data={}>
      <p class="title"> Неверный запрос!
      $if length errorMessage == 0
        <p class="subtitle"> Возможно, вы ввели что-то неверно
      $else
        <p .subtitle> #{errorMessage}
      <button .button x-on:click="history.back()"> Вернуться назад
|]

headlessTemplate :: Maybe String -> Html -> Html
headlessTemplate title' body = [shamlet|
$doctype 5
<html>
  <head>
    <title> #{fromMaybe "Labforge" title'}
    <meta charset=utf-8>
    <script defer src="/static/js/alpine.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/static/css/bulma.min.css">
  <body>
    <nav .navbar role="navigation" aria-label="Main navigation">
      <div .navbar-brand>
        <a .navbar-item>
          Labforge

      <div .navbar-menu #navMenu>
        <div .navbar-start>
          <a href=/ .navbar-item>
            Главная
          <a href=/docs/user-guide .navbar-item>
            Руководство
    ^{body}
    <footer .class>
      <div .content.has-text-centered>
        Labforge, by <a href="https://github.com/mrtstg"> Ilya Zamaratskikh </a>. <a href="https://github.com/mrtstg/labforge-oss"> Code </a> is licensed under GPLv3
|]

baseTemplate :: IntrospectResponse -> Maybe Html -> Maybe String -> Html -> Maybe Html -> AppT Html
baseTemplate token head' title' body afterBody = let
  lookMessages :: IntrospectResponse -> AppT [Text]
  lookMessages InactiveToken = pure []
  lookMessages token@(ActiveToken {}) = do
    messagesMap <- asks sessionMessages >>= liftIO . readTVarIO
    let res = fromMaybe [] $ M.lookup (fromMaybe "" $ tokenUUID token) messagesMap
    asks sessionMessages >>= \x -> (liftIO . atomically) $ modifyTVar x (M.insert (fromMaybe "" $ tokenUUID token) [])
    pure res
  in do
  messages <- lookMessages token
  let xinit = [("x-init" :: Text, T.intercalate ";" (map (\v -> "addNotification(\"" <> T.replace "\"" "\\\"" v <> "\")") messages))]
  pure [shamlet|
$doctype 5
<html>
  <head>
    <title> #{fromMaybe "Labforge" title'}
    $case head'
      $of (Just headHtml)
        ^{headHtml}
      $of Nothing
    <meta charset=utf-8>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script defer src="/static/js/alpine.js"></script>
    <link rel="stylesheet" href="/static/css/bulma.min.css">
  <body .is-flex.is-flex-direction-column style="min-height:100vh">
    <nav .navbar role="navigation" aria-label="Main navigation">
      <div .navbar-brand>
        <a .navbar-item>
          Labforge

        <a #navBurger role="button" class="navbar-burger" aria-label="menu" aria-expanded="false">
          <span aria-hidden="true">
          <span aria-hidden="true">
          <span aria-hidden="true">
          <span aria-hidden="true">

      <div .navbar-menu #navMenu>
        <div .navbar-start>
          <a href=/ .navbar-item>
            Главная
          <a href=/docs/user-guide .navbar-item>
            Руководство
        <div .navbar-end>
          $case token
            $of InactiveToken
              <a href=/api/auth/login class="button">
                Войти
            $of ActiveToken { .. }
              $if any (flip elem tokenRealmRoles) [grafanaAdmin, grafanaEditor, grafanaViewer]
                <a .navbar-item href=/grafana/> Мониторинг
              $if any (flip elem tokenRealmRoles) [deploymentAdmin, deploymentCreator, imageAdmin, imageViewer]
                <a .navbar-item href=/api/auth/portal> Портал
                <div .navbar-item.has-dropdown.is-hoverable>
                  <div .navbar-link> Администрирование
                  <div .navbar-dropdown>
                    $if any (flip elem tokenRealmRoles) [deploymentAdmin, deploymentCreator]
                      <a .navbar-item href=/deployment/create> Создать развертывание
                      <a .navbar-item href=/deployment/my> Мои развертывания
                    $if any (flip elem tokenRealmRoles) [imageViewer, imageAdmin]
                      <a .navbar-item href=/image/my> Все образы

              <div .navbar-item.has-dropdown.is-hoverable>
                <div .navbar-link>
                  #{ tokenUsername }
                <div .navbar-dropdown>
                  <a .navbar-item href=/api/auth/logout>
                    Выйти
    <div .is-fullheight.is-flex-grow-1 x-data="{ notifications: [], deleteNotification(i) { this.notifications.splice(i, 1) }, addNotification(message) {this.notifications.push(message);} }" *{xinit}>
      <div class="is-flex is-flex-direction-column-reverse" style="position:fixed;z-index:9999;bottom:0px;right:0px;max-width:500px;">
        <div x-show="notifications.length">
          <div .my-2.mx-5>
            <button .button.is-info.is-fullwidth @click="() => { notifications = [] }"> Очистить все
        <template x-for="(message, index) in notifications">
          <div .my-2.mx-5>
            <article .message>
              <div .message-header>
                <p> Уведомление
                <button .delete aria-label=delete @click="deleteNotification(index)">
              <div .message-body x-text=message>
      ^{body}
    <footer .class.mt-auto.p-3>
      <div .content.has-text-centered>
        <b>
          Labforge,
        by
        <a href="https://github.com/mrtstg">
          Ilya Zamaratskikh.
        <a href="https://github.com/mrtstg/labforge-oss">
          Code
        is licensed under GPLv3
  $case afterBody
    $of (Just afterHtml)
      ^{afterHtml}
    $of Nothing
  <script src="/static/js/navbar.js">
|]
