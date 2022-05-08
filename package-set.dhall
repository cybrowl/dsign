let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.21-20220215/package-set.dhall
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
    version = "v0.2.1",
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
  , version = "494824a2787aee24ab4a5888aa519deb05ecfd60"
  , dependencies = [] : List Text
  },
] : List Package

in  upstream # additions # overrides
