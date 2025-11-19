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
