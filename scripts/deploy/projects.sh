#!/bin/bash

# Load environment variables from the .env file
source .env

DEPLOY_ENV=${1:-$DEPLOY_ENV}

if [ "$DEPLOY_ENV" == "prod" ]; then
    echo "env: prod"

  DEPLOY_NETWORK="--network ic"
  DEPLOY_WALLET="--wallet=l2eht-qyaaa-aaaag-aaarq-cai"
else
    echo "env: dev"

  DEPLOY_NETWORK=""
  DEPLOY_WALLET=""
fi

export PROJECT_MAIN_PRINCIPAL=$(dfx canister ${DEPLOY_NETWORK} id project_main)

# Deploy
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} test_project --argument='(principal "'${PROJECT_MAIN_PRINCIPAL}'", false)'
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} project_main

# Check version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call test_project version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call project_main version

# Generate test interface
npm run generate_test_interface