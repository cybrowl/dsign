#!/bin/bash

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