#!/bin/bash

# Load environment variables from the .env file
source .env

DEPLOY_ENV=${1:-$DEPLOY_ENV}

if [ "$DEPLOY_ENV" == "prod" ]; then
    echo "env: prod"

  DEPLOY_NETWORK="--network ic"
  DEPLOY_WALLET="--wallet=l2eht-qyaaa-aaaag-aaarq-cai"
elif [ "$DEPLOY_ENV" == "staging" ]; then
    echo "env: staging"

  DEPLOY_NETWORK="--network staging"
  DEPLOY_WALLET="--wallet=l2eht-qyaaa-aaaag-aaarq-cai"
else
    echo "env: dev"

  DEPLOY_NETWORK=""
  DEPLOY_WALLET=""
fi

export FAVORITE_MAIN_PRINCIPAL=$(dfx canister ${DEPLOY_NETWORK} id favorite_main)

# Deploy
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} favorite_main

# Build Child Canister
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} test_favorite --argument='(principal "'${FAVORITE_MAIN_PRINCIPAL}'")'

# Check version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call test_favorite version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call favorite_main version

# Init
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call favorite_main initialize_canisters

# Generate test interface
npm run generate_test_interface
