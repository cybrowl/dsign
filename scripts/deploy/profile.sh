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
    echo "env: dev"
    cp ./src/env/env_local.mo ./src/env/env.mo

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

# Init
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call profile initialize_canisters

# Generate test interface
npm run generate_test_interface
