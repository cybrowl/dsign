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

# M-O
dfx deploy mo

# Creator
dfx deploy creator --argument='(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")'

# File Storage
dfx deploy file_storage --argument='(false, "8080", 10)'

# File Scaling
dfx deploy file_scaling_manager --argument='(false, "8080", 10)'

# Logger
dfx deploy logger

### Initialize Canisters
# Must be called before anything else
dfx canister call explore init '(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")' 
dfx canister call mo init '(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")' 

dfx canister call username_registry init
dfx canister call file_scaling_manager init
dfx canister call logger init

### Wait before deploying children
echo "Waiting for canisters to stabilize..."
sleep 15

### Deploy Children
npm run deploy:children
