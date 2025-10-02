{-# LANGUAGE MultiParamTypeClasses #-}
module Service.Environment
  ( ServiceEnvironment(..)
  , ServiceType(..)
  ) where

import           Servant.Client

data ServiceType =
  AuthService |
  ClusterManager |
  DeploymentService |
  KrokiProxy |
  JobserviceAPI deriving (Show, Eq, Enum)

class ServiceEnvironment a where
  getEnvFor :: ServiceType -> a -> ClientEnv
