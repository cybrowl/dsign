#!/bin/bash

# username
dfx deploy username
export USERNAME_ID=$(dfx canister id username)

# profile_avatar
dfx deploy profile_avatar_images
dfx deploy profile_avatar_main

# profile
dfx deploy profile
export PROFILE_ID=$(dfx canister id profile)

# projects
# dfx deploy project_main

# snaps
dfx deploy snap_images
dfx deploy snap
dfx deploy snap_main
export SNAP_MAIN_ID=$(dfx canister id snap_main)

# logger
dfx deploy logger

# canister_map
dfx deploy canister_map --argument '(record {profile = "'${PROFILE_ID}'"; snap_main = "'${SNAP_MAIN_ID}'"; username = "'${USERNAME_ID}'"; })'

# front end
dfx deploy dsign_assets

# killall dfx replica nodemanager