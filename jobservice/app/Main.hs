module Main (main) where

import           Init
import           System.IO

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  mainF
