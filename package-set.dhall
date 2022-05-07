let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.21-20220215/package-set.dhall
let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
   { name = "ulid"
   , repo = "https://github.com/aviate-labs/ulid.mo"
   , version = "master"
   , dependencies = [ "base" ] : List Text
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
