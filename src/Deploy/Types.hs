{-# LANGUAGE DeriveGeneric #-}
module Deploy.Types (TransactionData(..)) where

import qualified Data.Map as M
import Data.Aeson
import GHC.Generics

data TransactionData = TransactionData 
  { transactionIDMap :: !(M.Map String Int)
  } deriving (Show, Eq, Generic)

instance FromJSON TransactionData where

instance ToJSON TransactionData where
