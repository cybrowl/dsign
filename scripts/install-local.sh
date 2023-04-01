#!/bin/bash

# asset chunks
dfx deploy assets_file_chunks

# image asset staging
dfx deploy assets_img_staging

# logger
dfx deploy logger

# canister ids ledger
dfx deploy canister_ids_ledger

# health_metrics
dfx deploy health_metrics

# profile
dfx deploy profile

# projects
dfx deploy project_main

# snaps
dfx deploy snap_main

# snaps
dfx deploy favorite_main

# explore
dfx deploy explore

# front end
dfx deploy dsign_assets

export EXPLORE_PRINCIPAL=$(dfx canister id explore)
export FAVORITE_MAIN_PRINCIPAL=$(dfx canister id favorite_main)
export PROFILE_PRINCIPAL=$(dfx canister id profile)
export PROJECT_MAIN_PRINCIPAL=$(dfx canister id project_main)
export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)

# initialize canisters
dfx canister call canister_ids_ledger start_log_timer

dfx canister call canister_ids_ledger authorize_ids "(
    vec {
        \"${EXPLORE_PRINCIPAL}\";
        \"${FAVORITE_MAIN_PRINCIPAL}\";
        \"${PROFILE_PRINCIPAL}\";
        \"${PROJECT_MAIN_PRINCIPAL}\";
        \"${SNAP_MAIN_PRINCIPAL}\";
    }
)"

dfx canister call profile initialize_canisters 

dfx canister call snap_main set_canister_ids \
'(record {
    project_main = "'${PROJECT_MAIN_PRINCIPAL}'";
    favorite_main = "'${FAVORITE_MAIN_PRINCIPAL}'";
    })'

dfx canister call snap_main initialize_canisters

dfx canister call project_main initialize_canisters

dfx canister call favorite_main initialize_canisters

# test canisters
dfx deploy test_project --argument='(principal "'${PROJECT_MAIN_PRINCIPAL}'", false)'
dfx deploy test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy test_snap --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", principal "'${PROJECT_MAIN_PRINCIPAL}'", principal "'${FAVORITE_MAIN_PRINCIPAL}'")'

# killall dfx replica nodemanager

# dfx canister --network ic call canister_ids_ledger save_canister \
# '(record {
#     created = 1_670_321_001_063_287_000; 
#     id = "72zia-7aaaa-aaaag-aa37a-cai"; 
#     name = "Explore"; 
#     parent_name = "root"; 
#     isProd = true;
#     })'

