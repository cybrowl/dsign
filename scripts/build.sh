#!/bin/bash

## register canister identifiers
dfx canister create --all

## build
dfx build

## install 
dfx canister install --all