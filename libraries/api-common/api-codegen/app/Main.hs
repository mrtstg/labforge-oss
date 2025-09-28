module Main (main) where

import           Auth.Schema
import           Data.Proxy
import           Data.Text          (pack)
import           Servant.JS
import           System.Environment
import           System.FilePath

jsPath :: FilePath
jsPath = "../apiClients"

authApiJS :: CommonGeneratorOptions -> IO ()
authApiJS opts = writeJSForAPI (Proxy :: Proxy AuthAPI) (axiosWith (AxiosOptions True Nothing Nothing) opts) (jsPath `combine` "auth.js")

main :: IO ()
main = do
  args <- getArgs
  let opts = defCommonGeneratorOptions { urlPrefix = pack $ if null args then "" else head args }
  authApiJS opts
