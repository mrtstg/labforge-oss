module Deploy.TransactionSpec (spec) where

import Test.Hspec
import Data.Models.Config
import Data.Models.Config.Network
import Data.Models.Config.Template
import Data.Models.Config.VM
import Data.Models.Transaction
import Deploy.Transaction

spec :: Spec
spec = do
  describe "Transaction plan test" $ do
    it "Combined test" $ do
      let config = emptyDeployConfig 
            { deployNetworks = [ExistingNetwork "internet", SDNNetwork [] "zone" "name" Nothing] 
            , deployTemplates = [ConfigTemplate {configTemplateName = "template", configTemplateID = 101}]
            , deployVMs = [RawVM {configVMName = "raw", configVMID = Just 100, configVMDelay = 0}, TemplatedConfigVM {configVMParentTemplate = "template", configVMName = "vm2", configVMID = Nothing, configVMDelay = 0}]
            }
      planTransactionStages config `shouldBe` 
        [TemplateExists (ConfigTemplate {configTemplateName = "template", configTemplateID = 101}),NetworkExists (ExistingNetwork {configNetworkName = "internet"}),NetworkExists (SDNNetwork {configNetworkSubnets = [], configNetworkZone = "zone", configNetworkName = "name", configNetworkVLANAware = Nothing}),VMExists (RawVM {configVMName = "raw", configVMID = Just 100, configVMDelay = 0}),VMExists (TemplatedConfigVM {configVMParentTemplate = "template", configVMName = "vm2", configVMID = Nothing, configVMDelay = 0})]
