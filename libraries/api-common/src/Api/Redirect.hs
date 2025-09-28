{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
module Api.Redirect
  ( redirectTo
  , tempRedirectTo
  ) where

import           Control.Monad.Except
import qualified Data.ByteString.Char8 as BS
import           Servant

redirectTo :: (MonadError ServerError m) => String -> m a
redirectTo location = throwError $ err301 { errHeaders = [("Location", BS.pack location)] }

tempRedirectTo :: (MonadError ServerError m) => String -> m a
tempRedirectTo location = throwError $ err307 { errHeaders = [("Location", BS.pack location)] }
