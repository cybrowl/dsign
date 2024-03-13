#!/bin/bash

# Load environment variables from the .env file
source .env

DEPLOY_ENV=${1:-$DEPLOY_ENV}

if [ "$DEPLOY_ENV" == "prod" ]; then
    echo "env: prod"
    cp ./src/env/env_ic.mo ./src/env/env.mo

    DEPLOY_NETWORK="--network ic"
    DEPLOY_WALLET="--wallet=l2eht-qyaaa-aaaag-aaarq-cai"

elif [ "$DEPLOY_ENV" == "staging" ]; then
    echo "env: staging"
    cp ./src/env/env_staging.mo ./src/env/env.mo

    DEPLOY_NETWORK="--network staging"
    DEPLOY_WALLET="--wallet=l2eht-qyaaa-aaaag-aaarq-cai"

else
    echo "Unsupported deployment environment. Only 'prod' and 'staging' are supported."
    exit 1
fi

# Username Registry
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} username_registry
export USERNAME_REGISTRY_CANISTER_ID=$(dfx canister id username_registry)

# Explore
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} explore
export EXPLORE_CANISTER_ID=$(dfx canister id explore)

# Creator
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} creator --argument='(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")'

# File Storage
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} file_storage --argument='(true, "8080")'

# File Scaling
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} file_scaling_manager --argument='(true, "8080")'

# Logger
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} logger

### Initialize Canisters
# Must be called before anything else
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call explore init '(principal "'${USERNAME_REGISTRY_CANISTER_ID}'")' 

dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call username_registry init 
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call creator init 
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call file_scaling_manager init  
