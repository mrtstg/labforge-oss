# keycloak-api

Haskell library for working with Keycloak API with partial bindings to
admin API and OAuth2 API using servant.

## Preparing test client in GHCi

```haskell
:set -XOverloadedStrings
import Servant.Client
import Network.HTTP.Conduit
import Network.HTTP.Client.Conduit
import Data.Text
baseUrl <- parseBaseUrl "<KEYCLOAK_URL>"
manager <- (Network.HTTP.Conduit.newManager defaultManagerSettings)
let env = mkClientEnv manager baseUrl
let realm = "<REALM_NAME>" :: Text
let cid = "<CLIENT_ID>"
let csecret = "<CLIENT_SECRET>"
flip runClientM env $ do -- your request method here
