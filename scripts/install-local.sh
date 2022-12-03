#!/bin/bash

# asset chunks
dfx deploy assets_file_chunks

# image asset staging
dfx deploy assets_img_staging

# profile
dfx deploy profile
export PROFILE_ID=$(dfx canister id profile)

# projects
dfx deploy project_main
export PROJECT_MAIN_PRINCIPAL=$(dfx canister id project_main)

# logger
dfx deploy logger

# snaps
dfx deploy snap_main
export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)

# explore
dfx deploy explore

# front end
dfx deploy dsign_assets

# killall dfx replica nodemanager