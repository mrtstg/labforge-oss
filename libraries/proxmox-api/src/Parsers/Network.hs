{-# LANGUAGE OverloadedStrings #-}
module Parsers.Network (parseNetworkDevice, parseChangesConfig, interfacePendingState) where

import           Data.Attoparsec.Text
import qualified Data.Map             as M
import           Data.Text            (Text)

data ChangesLine = OtherLine String | InterfaceAdded String | InterfaceRemoved String deriving (Show, Eq)

interfacePendingState :: Text -> String -> Either String Bool
interfacePendingState changesConfig interfaceName = do
  parseRes <- parseChangesConfig changesConfig
  let isDeleted = InterfaceRemoved interfaceName `elem` parseRes
  let isAdded = InterfaceAdded interfaceName `elem` parseRes
  case (isDeleted, isAdded) of
    (True, _) -> pure False
    (False, True) -> pure True
    _anyOther -> Left $ "Interface " <> interfaceName <> " did not changed state."

parseChangesConfig :: Text -> Either String [ChangesLine]
parseChangesConfig = parseOnly (manyTill (choice [interfaceLineParser, otherLineParser]) endOfInput)

interfaceLineParser :: Parser ChangesLine
interfaceLineParser = do
  sym <- satisfy (`elem` ['+', '-'])
  _ <- string "iface"
  _ <- many1 space
  iface <- manyTill anyChar space
  _ <- manyTill anyChar endOfLine
  pure $ (if sym == '+' then InterfaceAdded else InterfaceRemoved) iface

otherLineParser :: Parser ChangesLine
otherLineParser = do
  line <- manyTill anyChar endOfLine
  pure $ OtherLine line

parseNetworkDevice :: Text -> Either String (M.Map String String)
parseNetworkDevice = fmap M.fromList . parseOnly networkArgsParser

networkArgsParser :: Parser [(String, String)]
networkArgsParser = sepBy networkArgParser (char ',')

networkArgParser :: Parser (String, String)
networkArgParser = do
  key <- many1 (satisfy (`notElem` ['=', ',']))
  char '='
  value <- many1 (satisfy (`notElem` ['=', ',']))
  return (key, value)
