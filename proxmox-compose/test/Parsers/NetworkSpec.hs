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
module Parsers.NetworkSpec (spec) where

import           Data.Either
import qualified Data.Map        as M
import           Parsers.Network
import           Test.Hspec

spec :: Spec
spec = do
  describe "Network device string parse test" $ do
    it "Empty string test" $ do
      parseNetworkDevice "" `shouldBe` Right M.empty
    it "Simple keypair test" $ do
      parseNetworkDevice "a=b" `shouldBe` Right (M.fromList [("a", "b")])
      parseNetworkDevice "1=2" `shouldBe` Right (M.fromList [("1", "2")])
      parseNetworkDevice "a1=2b" `shouldBe` Right (M.fromList [("a1", "2b")])
    it "Invalid data tests" $ do
      parseNetworkDevice "=" `shouldBe` Right M.empty
      parseNetworkDevice "key=" `shouldBe` Right M.empty
      parseNetworkDevice "=value" `shouldBe` Right M.empty
    it "Real data tests" $ do
      parseNetworkDevice "virtio=BC:24:11:B1:57:75,bridge=internet,firewall=1" `shouldBe`
        Right (M.fromList [("virtio", "BC:24:11:B1:57:75"),("bridge", "internet"), ("firewall", "1")])
