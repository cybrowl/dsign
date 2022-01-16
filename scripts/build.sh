#!/bin/bash

# DFX BUILD #
## stop
dfx stop

## start clean
dfx start --clean --background

## register canister identifiers
dfx canister create --all

## build
dfx build

## install 
dfx canister install --all

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

# profile
cp .dfx/local/canisters/profile/profile.did.js .dfx/local/canisters/profile/profile.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/profile/profile.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/profile/profile.did.test.cjs

# profile_manager
cp .dfx/local/canisters/profile_manager/profile_manager.did.js .dfx/local/canisters/profile_manager/profile_manager.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/profile_manager/profile_manager.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/profile_manager/profile_manager.did.test.cjs