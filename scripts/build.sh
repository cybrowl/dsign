#!/bin/bash

## start clean local execution env 
dfx start --clean --background

## register canister identifiers
dfx canister create --all

## build
dfx build

## install 
dfx canister install --all