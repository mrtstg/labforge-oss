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
