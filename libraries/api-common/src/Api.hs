{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
module Api where

import           Api.Keycloak.Models
import           Data.Aeson
import           Data.Bifunctor
import           Data.Either
import qualified Data.Map            as M
import           Servant.API

type AuthHeader = Header' '[Required] "Authorization" BearerWrapper

data PagedResponse t = PagedResponse
  { responsePageSize :: !Int
  , responseTotal    :: !Int
  , responseObjects  :: !t
  } deriving Show

hasNextPages :: Int -> PagedResponse a -> Bool
hasNextPages page (PagedResponse {responseTotal=totalAmount, responsePageSize=pageSize }) =
  totalAmount - page * pageSize > 0

iteratePagedResponse :: (Monad m) => (Int -> m (PagedResponse [a])) -> m [a]
iteratePagedResponse f' = helper f' 1 [] where
  helper :: (Monad m) => (Int -> m (PagedResponse [a])) -> Int -> [a] -> m [a]
  helper f page acc = do
    v <- f page
    if hasNextPages page v then helper f (page + 1) (responseObjects v ++ acc) else pure (responseObjects v ++ acc)

genericClientLoseGather :: (Monad m, Ord a) => [a] -> (a -> m (Either e r)) -> m (M.Map a r)
genericClientLoseGather keys f = do
  apiData <- mapM (\k -> f k >>= \r -> pure (k, r)) keys
  pure $ (M.fromList . map (second $ fromRight undefined) . filter (isRight . snd)) apiData

instance (ToJSON t) => ToJSON (PagedResponse t) where
  toJSON (PagedResponse { .. }) = object
    [ "pageSize" .= responsePageSize
    , "total" .= responseTotal
    , "objects" .= responseObjects
    ]

instance (FromJSON t) => FromJSON (PagedResponse t) where
  parseJSON = withObject "PagedResponse" $ \v -> PagedResponse
    <$> v .: "pageSize"
    <*> v .: "total"
    <*> v .: "objects"
