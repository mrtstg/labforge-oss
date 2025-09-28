module Api.BaseUrl (tryParseUrl) where

import           Control.Monad.Catch
import           Control.Monad.IO.Class
import           Data.Functor           ((<&>))
import           Servant.Client

tryParseUrl :: (MonadIO m, MonadCatch m) => String -> m (Either String BaseUrl)
tryParseUrl url = (parseBaseUrl url <&> Right) `catchAll` (pure . Left . show)
