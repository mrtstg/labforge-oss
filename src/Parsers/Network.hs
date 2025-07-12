{-# LANGUAGE OverloadedStrings #-}
module Parsers.Network (parseNetworkDevice) where

import           Data.Attoparsec.Text
import qualified Data.Map             as M
import           Data.Text

parseNetworkDevice :: String -> Either String (M.Map String String)
parseNetworkDevice = fmap M.fromList . parseOnly networkArgsParser . pack

networkArgsParser :: Parser [(String, String)]
networkArgsParser = sepBy networkArgParser (char ',')

networkArgParser :: Parser (String, String)
networkArgParser = do
  key <- many1 (satisfy (`notElem` ['=', ',']))
  char '='
  value <- many1 (satisfy (`notElem` ['=', ',']))
  return (key, value)
