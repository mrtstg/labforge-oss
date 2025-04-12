module Main (main) where

import App.Parser
import Options.Applicative
import App.Commands

main :: IO ()
main = do
  opts <- execParser (info (appParser <**> helper) fullDesc)
  runCommand opts
