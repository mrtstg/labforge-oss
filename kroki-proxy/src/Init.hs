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
module Init
    ( mainF
    ) where

import           App.Commands
import           App.Parser
import           Control.Monad       (when)
import           LoadEnv
import           Options.Applicative
import           System.Directory

mainF :: IO ()
mainF = do
  envFileExists <- doesFileExist "./.env"
  when envFileExists $ do
    loadEnvFrom "./.env"
  opts <- execParser (info (appParser <**> helper) fullDesc)
  runCommand opts
