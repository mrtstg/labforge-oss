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
  subparser (
    command "up" (info deployParser (progDesc "Deploy VMs")) <>
    command "down" (info destroyParser (progDesc "Destroy VMs"))
  )
