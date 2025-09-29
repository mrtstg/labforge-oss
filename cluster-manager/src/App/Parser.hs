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
module App.Parser
  ( appParser
  ) where

import           App.Types
import           Options.Applicative

runServerParser :: Parser AppCommand
runServerParser = RunServerOn
  <$> option auto (long "port" <> short 'p' <> metavar "PORT" <> help "Server port to launch on")
  <*> switch (long "migrate" <> help "Execute migrations before launch")

runMigrationsParser :: Parser AppCommand
runMigrationsParser = pure MakeMigrations

checkNodeParser :: Parser AppCommand
checkNodeParser = CheckNode
  <$> option str (long "node" <> help "Node to check")

deleteNodeParser :: Parser AppCommand
deleteNodeParser = RemoveNode
  <$> option str (long "node" <> help "Node to remove")

createNodeParser :: Parser AppCommand
createNodeParser = AddNode
  <$> option str (long "name" <> help "Node name (should be matching with name in PVE)")
  <*> option str (long "api-url" <> help "Node API URL")
  <*> switch (long "ignore-ssl" <> help "Ignore SSL check")
  <*> option str (long "token" <> help "PVE API token")
  <*> option auto (long "start-vmid" <> value 100 <> help "VMID to start from")
  <*> option str (long "agent-url" <> help "Proxmox agent URL")
  <*> option str (long "agent-token" <> help "Proxmox agent token")
  <*> option str (long "display-network" <> value "0.0.0.0" <> help "Display network to listen")
  <*> option auto (long "min-display" <> value 100 <> help "Start display value")
  <*> option auto (long "max-display" <> value 5000 <> help "Max display value")
  <*> option str (long "display-ip" <> help "Address for connecting to display")
  <*> some (option auto (short 'p' <> help "Displays for excluding"))

appParser :: Parser AppOpts
appParser = AppOpts <$>
  switch (long "verbose" <> short 'v' <> help "Enable verbose logging") <*>
  subparser (
    command "run" (info runServerParser (progDesc "Run server")) <>
    command "migrate" (info runMigrationsParser (progDesc "Run migrations")) <>
    command "delete" (info deleteNodeParser (progDesc "Remove node from DB")) <>
    command "check" (info checkNodeParser (progDesc "Check API availability")) <>
    command "create-node" (info createNodeParser (progDesc "Add node to DB"))
    )
