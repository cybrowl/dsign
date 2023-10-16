#!/bin/bash
export EXPLORE_PRINCIPAL=$(dfx canister id explore)
export FAVORITE_MAIN_PRINCIPAL=$(dfx canister id favorite_main)
export PROFILE_PRINCIPAL=$(dfx canister id profile)
export PROJECT_MAIN_PRINCIPAL=$(dfx canister id project_main)
export CANISTER_IDS_LEDGER_PRINCIPAL=$(dfx canister id canister_ids_ledger)

dfx canister call canister_ids_ledger save_canister \
'(record {
    created = 1_670_321_001_063_287_000; 
    id = "'${CANISTER_IDS_LEDGER_PRINCIPAL}'"; 
    name = "CANISTER_IDS_LEDGER"; 
    parent_name = "root"; 
    isProd = false;
    })'

dfx canister call canister_ids_ledger save_canister \
'(record {
    created = 1_670_321_001_063_287_000; 
    id = "'${EXPLORE_PRINCIPAL}'"; 
    name = "Explore"; 
    parent_name = "root"; 
    isProd = false;
    })'

dfx canister call canister_ids_ledger save_canister \
'(record {
    created = 1_670_321_001_063_287_000; 
    id = "'${FAVORITE_MAIN_PRINCIPAL}'"; 
    name = "FAVORITE_MAIN"; 
    parent_name = "root"; 
    isProd = false;
    })'

dfx canister call canister_ids_ledger save_canister \
'(record {
    created = 1_670_321_001_063_287_000; 
    id = "'${PROFILE_PRINCIPAL}'"; 
    name = "PROFILE"; 
    parent_name = "root"; 
    isProd = false;
    })'

dfx canister call canister_ids_ledger save_canister \
'(record {
    created = 1_670_321_001_063_287_000; 
    id = "'${PROJECT_MAIN_PRINCIPAL}'"; 
    name = "PROJECT_MAIN"; 
    parent_name = "root"; 
    isProd = false;
    })'

dfx canister call canister_ids_ledger save_canister \
'(record {
    created = 1_670_321_001_063_287_000; 
    id = "'${SNAP_MAIN_PRINCIPAL}'"; 
    name = "SNAP_MAIN"; 
    parent_name = "root"; 
    isProd = false;
    })'