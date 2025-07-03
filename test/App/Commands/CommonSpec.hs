module App.Commands.CommonSpec (spec) where

import Test.Hspec
import App.Commands.Common

spec :: Spec
spec = do
  describe "State filepath generator test" $ do
    it "Local directory test" $ do
      defaultStatePathGenerator "proxmox-compose.yaml" `shouldBe` "./.proxmox-compose-state.json"
      defaultStatePathGenerator "file.yml" `shouldBe` "./.file-state.json"
      defaultStatePathGenerator "state.tar.gz" `shouldBe` "./.state-state.json"
    it "Remote directory test" $ do
      defaultStatePathGenerator "/opt/state.yaml" `shouldBe` "/opt/.state-state.json"
      defaultStatePathGenerator "/opt/proxmox-compose.yaml" `shouldBe` "/opt/.proxmox-compose-state.json"
