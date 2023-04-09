let upstream = https://github.com/internet-computer/base-package-set/releases/download/moc-0.7.4/package-set.dhall sha256:3a20693fc597b96a8c7cf8645fda7a3534d13e5fbda28c00d01f0b7641efe494
let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
  { 
    name = "array",
    repo = "https://github.com/aviate-labs/array.mo",
    version = "main", 
    dependencies = ["base-0.7.3" ] : List Text
  },
  {
    name = "parser-combinators",
    repo = "https://github.com/aviate-labs/parser-combinators.mo",
    version = "v0.1.2",
    dependencies = [ "base-0.7.3" ] : List Text
  },
  {
    name = "json",
    repo = "https://github.com/aviate-labs/json.mo",
    version = "v0.2.1",
    dependencies = [ "base-0.7.3", "parser-combinators" ] : List Text
  },
  { 
    name = "ulid",
    repo = "https://github.com/aviate-labs/ulid.mo",
    version = "main", 
    dependencies = [ "base-0.7.3" ] : List Text
  },
  {
    name = "io",
    repo = "https://github.com/cybrowl/io.mo",
    version = "main",
    dependencies = [ "base-0.7.3" ]
  },
  {
    name = "rand",
    repo = "https://github.com/cybrowl/rand.mo.git",
    version = "main",
    dependencies = [ "base-0.7.3" ]
  },
  {
    name = "encoding",
    repo = "https://github.com/aviate-labs/encoding.mo",
    version = "v0.4.1",
    dependencies = [ "base-0.7.3", "array" ]
  },
  {
    name = "hashmap",
    repo = "https://github.com/ZhenyaUsenko/motoko-hash-map",
    version = "v8.1.0",
    dependencies = [] : List Text
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
