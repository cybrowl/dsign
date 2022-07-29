let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.7-20210818/package-set.dhall sha256:c4bd3b9ffaf6b48d21841545306d9f69b57e79ce3b1ac5e1f63b068ca4f89957
let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
  { 
    name = "array",
    repo = "https://github.com/aviate-labs/array.mo",
    version = "main", 
    dependencies = [] : List Text
  },
  { 
    name = "ulid",
    repo = "https://github.com/aviate-labs/ulid.mo",
    version = "main", 
    dependencies = [ "base" ] : List Text
  },
  {
    name = "io",
    repo = "https://github.com/aviate-labs/io.mo",
    version = "main",
    dependencies = [ "base" ]
  },
  {
    name = "rand",
    repo = "https://github.com/aviate-labs/rand.mo",
    version = "be7f60e428a3805141cd4e2741c2b493086bca0f",
    dependencies = [ "base" ]
  },
  {
    name = "encoding",
    repo = "https://github.com/aviate-labs/encoding.mo",
    version = "8e0fe1d8f5c2d284e77d719703c42e0e271839b1",
    dependencies = [ "base" ]
  },
] : List Package

let overrides = [
  { name = "base"
  , repo = "https://github.com/dfinity/motoko-base"
  , version = "master"
  , dependencies = [] : List Text
  },
] : List Package

in  upstream # additions # overrides
