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

export SNAP_MAIN_PRINCIPAL=$(dfx canister ${DEPLOY_NETWORK} id snap_main)
export PROJECT_MAIN_PRINCIPAL=$(dfx canister ${DEPLOY_NETWORK} id project_main)
export FAVORITE_MAIN_PRINCIPAL=$(dfx canister ${DEPLOY_NETWORK} id favorite_main)

# Deploy
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} test_snap --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", principal "'${PROJECT_MAIN_PRINCIPAL}'", principal "'${FAVORITE_MAIN_PRINCIPAL}'")'
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} snap_main

# dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call snap_main initialize_canisters

# Check version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call test_assets version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call test_image_assets version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call test_snap version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call snap_main version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call snap_main initialize_canisters

# Generate test interface
npm run generate_test_interface

# GENERATE WASM FOR NETWORK IC
