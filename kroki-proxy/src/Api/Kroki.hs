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
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE TypeOperators         #-}
module Api.Kroki
  ( KrokiAPI
  , renderD2
  , DiagramRequest(..)
  , SVG
  ) where

import           Data.Aeson
import           Data.ByteString.Lazy.Char8
import           Data.Text                  (Text)
import qualified Data.Text                  as T
import           Servant
import           Servant.Client

newtype DiagramRequest = DiagramRequest Text deriving (Show, Eq)

instance ToJSON DiagramRequest where
  toJSON (DiagramRequest r) = object [ "diagram_source" .= r ]

data SVG

instance Accept SVG where
  contentType _ = "image/svg+xml"

instance MimeRender SVG ByteString where
  mimeRender _ = id

instance MimeUnrender SVG Text where
  mimeUnrender _ = pure . T.pack . unpack

type KrokiAPI = "d2" :> "svg" :> ReqBody '[JSON] DiagramRequest :> Post '[SVG] Text

krokiProxy :: Proxy KrokiAPI
krokiProxy = Proxy

renderD2 = client krokiProxy
