{-# LANGUAGE MultiParamTypeClasses #-}
module Service.Environment
  ( ServiceEnvironment(..)
  , ServiceType(..)
  , serviceTypeToPrefix
  ) where

import           Servant.Client

data ServiceType =
  AuthService |
  ClusterManager |
  DeploymentService |
  KrokiProxy |
  JobserviceAPI |
  Keycloak | KrokiServer deriving (Show, Eq, Enum)

serviceTypeToPrefix :: ServiceType -> String
serviceTypeToPrefix AuthService       = "AUTH"
serviceTypeToPrefix ClusterManager    = "CLUSTER"
serviceTypeToPrefix DeploymentService = "DEPLOYMENT"
serviceTypeToPrefix KrokiProxy        = "KROKI"
serviceTypeToPrefix JobserviceAPI     = "JOBSERVICE"
serviceTypeToPrefix Keycloak          = "KEYCLOAK"
serviceTypeToPrefix KrokiServer       = "KROKI_SERVER"

class ServiceEnvironment a where
  getEnvFor :: ServiceType -> a -> ClientEnv
