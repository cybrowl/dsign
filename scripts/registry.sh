#!/bin/bash

# Load environment variables from the .env file
source .env

DEPLOY_ENV=${1:-$DEPLOY_ENV}

if [ "$DEPLOY_ENV" == "prod" ]; then
    echo "------------------------------"
    echo "env: prod"
    echo "------------------------------"
    cp ./src/env/env_ic.mo ./src/env/env.mo

    DEPLOY_NETWORK="--network ic"
    DEPLOY_WALLET="--wallet=l2eht-qyaaa-aaaag-aaarq-cai"

elif [ "$DEPLOY_ENV" == "staging" ]; then
    echo "------------------------------"
    echo "env: staging"
    echo "------------------------------"

    cp ./src/env/env_staging.mo ./src/env/env.mo

    DEPLOY_NETWORK="--network staging"
    DEPLOY_WALLET="--wallet=l2eht-qyaaa-aaaag-aaarq-cai"

else
    echo "Unsupported deployment environment. Only 'prod' and 'staging' are supported."
    exit 1
fi


dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call username_registry get_registry

dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call file_scaling_manager get_file_storage_registry

dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call explore get_registry

dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call username_registry send_all_canister_info_to_mo

dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call mo get_registry