#!/bin/bash

echo "env: dev"
cp ./src/env/env_local.mo ./src/env/env.mo

# Cycles
dfx ledger fabricate-cycles --all

# II
dfx deploy internet_identity

# Username Registry
dfx deploy username_registry
export USERNAME_REGISTRY_CANISTER_ID=$(dfx canister id username_registry)

# Explore
dfx deploy explore
export EXPLORE_CANISTER_ID=$(dfx canister id explore)

# Creator
dfx deploy creator --argument='(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")'

# File Storage
dfx deploy file_storage --argument='(false, "8080")'

# File Scaling
dfx deploy file_scaling_manager --argument='(false, "8080")'

# Logger
dfx deploy logger

### Initialize Canisters
dfx canister call explore init '(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")' # Must be called before anything else

dfx canister call username_registry init # init
dfx canister call creator init # init
dfx canister call file_scaling_manager init  # init



# Test All
# npm run test
