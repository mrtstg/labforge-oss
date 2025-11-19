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
module App.Parser (appParser) where

import App.Types
import Options.Applicative

deployParser :: Parser AppCommand
deployParser = pure Deploy

destroyParser :: Parser AppCommand
destroyParser = pure Destroy

appParser :: Parser AppOpts
appParser = AppOpts <$>
  optional (strOption (long "file" <> short 'f' <> metavar "FILE" <> help "Path to configuration file")) <*>
  optional (strOption (long "token" <> short 't' <> metavar "TOKEN" <> help "Proxmox API access token to use")) <*>
  switch (short 'v' <> long "verbose" <> help "Enable verbose logging") <*>
  subparser (
    command "up" (info deployParser (progDesc "Deploy VMs")) <>
    command "down" (info destroyParser (progDesc "Destroy VMs"))
  )
