#!/bin/bash

echo "env: dev"
cp ./src/env/env_local.mo ./src/env/env.mo

# Cycles
dfx ledger fabricate-cycles --all

# II
dfx deploy internet_identity

# Username Registry
dfx deploy username_registry
dfx canister call username_registry init # init

export USERNAME_REGISTRY_PRINCIPAL=$(dfx canister id username_registry)

# Creator
dfx deploy creator --argument='(principal "'${USERNAME_REGISTRY_PRINCIPAL}'")'

# Explore
dfx deploy explore --argument='(principal "'${USERNAME_REGISTRY_PRINCIPAL}'")'

export EXPLORE_CANISTER_ID=$(dfx canister id explore)

# Set Explore CID in Username Registry
dfx canister call username_registry set_explore_canister_id '("'${EXPLORE_CANISTER_ID}'")'

# File Storage
dfx deploy file_storage --argument='(false, "8080")'

# File Scaling
dfx deploy file_scaling_manager --argument='(false, "8080")'
dfx canister call file_scaling_manager init  # init

# Logger
dfx deploy logger

# Test All
# npm run test
