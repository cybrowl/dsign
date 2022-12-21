#!/bin/bash

# asset chunks
dfx deploy assets_file_chunks

# image asset staging
dfx deploy assets_img_staging

# logger
dfx deploy logger

# canister ids ledger
dfx deploy canister_ids_ledger

# profile
dfx deploy profile
export PROFILE_PRINCIPAL=$(dfx canister id profile)

# projects
dfx deploy project_main
export PROJECT_MAIN_PRINCIPAL=$(dfx canister id project_main)

# snaps
dfx deploy snap_main
export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)

# snaps
dfx deploy favorite_main
export FAVORITE_MAIN_PRINCIPAL=$(dfx canister id favorite_main)

# explore
dfx deploy explore
export EXPLORE_PRINCIPAL=$(dfx canister id explore)

# front end
dfx deploy dsign_assets

# init
dfx canister call canister_ids_ledger set_canister_ids \
'(record {
    explore = "'${EXPLORE_PRINCIPAL}'";
    favorite_main = "'${FAVORITE_MAIN_PRINCIPAL}'";
    profile = "'${PROFILE_PRINCIPAL}'";
    project_main = "'${PROJECT_MAIN_PRINCIPAL}'";
    snap_main = "'${SNAP_MAIN_PRINCIPAL}'";
    })'

dfx canister call profile initialize_canisters 

dfx canister call snap_main initialize_canisters

dfx canister call project_main initialize_canisters

dfx canister call favorite_main initialize_canisters

# test canisters
dfx deploy test_project --argument='(principal "'${PROJECT_MAIN_PRINCIPAL}'", false)'
dfx deploy test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy test_snap --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", principal "'${PROJECT_MAIN_PRINCIPAL}'", principal "'${FAVORITE_MAIN_PRINCIPAL}'")'

# killall dfx replica nodemanager

# dfx canister --network ic call canister_child_ledger save_canister \
# '(record {
#     created = 1_670_321_001_063_287_000; 
#     id = "lrr5x-jaaaa-aaaag-aatzq-cai"; 
#     name = "snap"; 
#     parent_name = "SnapMain"; 
#     isProd = true;
#     })'

