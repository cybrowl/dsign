#!/bin/bash

# username
dfx deploy username
export USERNAME_ID=$(dfx canister id username)

# asset chunks
dfx deploy assets_file_chunks

# image asset staging
dfx deploy assets_img_staging

# profile
dfx deploy profile
export PROFILE_ID=$(dfx canister id profile)

# projects
dfx deploy project_main

# logger
dfx deploy logger

# snaps
dfx deploy snap_main
export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)

# front end
dfx deploy dsign_assets

# test canisters
dfx deploy test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'

# killall dfx replica nodemanager