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
module Utils.Time
  ( getUnixIntTime
  , getUnixIntTimeMs
  , formatUnixTime
  , formatUnixTimeLocal
  ) where

import           Control.Monad.IO.Class
import           Data.Functor           ((<&>))
import           Data.Time
import           Data.Time.Clock.POSIX
import           Data.Time.Format       (defaultTimeLocale, formatTime)

defaultFormatTimeString = "%Y-%m-%d %H:%M:%S"

defaultFormatTZTimeString = "%Y-%m-%d %H:%M:%S %Z"

getUnixIntTimeMs :: (MonadIO m) => m Int
getUnixIntTimeMs = liftIO getPOSIXTime <&> (floor . (* 1000))

getUnixIntTime :: (MonadIO m) => m Int
getUnixIntTime = do
  posixTime <- liftIO getPOSIXTime
  (pure . fromIntegral . floor) posixTime

formatUnixTimeLocal :: Real a => a -> IO String
formatUnixTimeLocal timestamp = utcToLocalZonedTime (posixSecondsToUTCTime $ realToFrac timestamp) <&> formatTime defaultTimeLocale defaultFormatTZTimeString

formatUnixTime :: Real a => a -> String
formatUnixTime timestamp = formatTime defaultTimeLocale defaultFormatTimeString (posixSecondsToUTCTime (realToFrac timestamp))
