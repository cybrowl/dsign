#!/bin/bash

echo "env: dev"
cp ./src/env/env_local.mo ./src/env/env.mo

# II
dfx deploy internet_identity

# Explore
dfx deploy explore

# Logger
dfx deploy logger

# Username Registry
dfx deploy username_registry

# Initialize Username Registry
dfx canister call username_registry initialize_canisters 

# export EXPLORE_PRINCIPAL=$(dfx canister id explore)
# export LOGGER_PRINCIPAL=$(dfx canister id logger)
export USERNAME_REGISTRY_PRINCIPAL=$(dfx canister id username_registry)

# Creator
dfx deploy creator --argument='(principal "'${USERNAME_REGISTRY_PRINCIPAL}'")'

# File Storage
dfx deploy file_storage --argument='(false, "8080")'

# File Scaling
dfx deploy file_scaling_manager --argument='(false, "8080")'

