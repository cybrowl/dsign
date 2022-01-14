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
## make `did` file compatible 
cp .dfx/local/canisters/profile/profile.did.js .dfx/local/canisters/profile/profile.did.test.js

## update file OSX ONLY (Linux remove '')
sed -i '' 's/export//g' .dfx/local/canisters/profile/profile.did.test.js
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/profile/profile.did.test.js