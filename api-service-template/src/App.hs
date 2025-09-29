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
module App (app) where

import           Api.Sample
import           Config
import           Control.Monad.Reader
import           Data.Aeson
import           Servant

type CombinedAPI = SampleAPI

combinedServerT :: ServerT CombinedAPI AppT
combinedServerT = sampleServer

combinedServer :: Config -> Server CombinedAPI
combinedServer cfg = hoistServer combinedApi (runServer cfg) combinedServerT

combinedApi :: Proxy CombinedAPI
combinedApi = Proxy

runServer :: Config -> AppT m -> Handler m
runServer cfg appV = flip runReaderT cfg $ runApp appV

app :: Config -> Application
app cfg = serveWithContext combinedApi (errorFormatters :. EmptyContext) (combinedServer cfg)

errorFormatters :: ErrorFormatters
errorFormatters = defaultErrorFormatters
  { bodyParserErrorFormatter = \_ _ e -> err400 { errBody = (encode . object) [ "error" .= e ] }
  , notFoundErrorFormatter = const err404 { errBody = (encode . object) [ "error" .= String "Not found" ] }
  }
