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

export PROFILE_PRINCIPAL=$(dfx canister ${DEPLOY_NETWORK} id profile)

# Deploy
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} test_image_assets --argument='(principal "'${PROFILE_PRINCIPAL}'", false)'
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} profile

# Check version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call test_image_assets version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call profile version

# Generate test interface
npm run generate_test_interface