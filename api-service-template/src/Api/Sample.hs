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
{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE TypeOperators     #-}
module Api.Sample
  ( sampleServer
  , SampleAPI
  ) where

import           Config
import           Control.Monad.Logger
import           Data.Aeson
import qualified Data.Text            as T
import           Database
import           Database.Persist
import           Servant

type SampleAPI = "" :> Get '[JSON] Int

sampleAPI :: Proxy SampleAPI
sampleAPI = Proxy

sampleServer :: ServerT SampleAPI AppT
sampleServer = sampleMethod

sampleMethod = undefined
