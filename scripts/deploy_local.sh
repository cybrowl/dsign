#!/bin/bash

echo "env: dev"
cp ./src/env/env_local.mo ./src/env/env.mo

# Cycles
dfx ledger fabricate-cycles --all --network local

# II
dfx deploy internet_identity --network local

# Username Registry
dfx deploy username_registry --network local
export USERNAME_REGISTRY_CANISTER_ID=$(dfx canister --network local id username_registry)

# Explore
dfx deploy explore --network local

# M-O
dfx deploy mo --network local

# Creator
dfx deploy creator --network local --argument='(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")'

# File Storage
dfx deploy file_storage --network local --argument='(false, "8080", 10)'

# File Scaling
dfx deploy file_scaling_manager --network local --argument='(false, "8080", 10)'

# Logger
dfx deploy logger --network local

### Initialize Canisters
# Must be called before anything else
dfx canister --network local call explore init '(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")'
dfx canister --network local call mo init '(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")'

dfx canister --network local call username_registry init
dfx canister --network local call file_scaling_manager init
dfx canister --network local call logger init

### Wait before deploying children
echo "Waiting for canisters to stabilize..."
sleep 15

### Deploy Children
npm run deploy:children
