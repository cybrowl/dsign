#!/bin/bash

dfx stop
dfx start --background --clean

dfx deploy profile_avatar
export PROFILE_AVATAR_ID=$(dfx canister id profile_avatar)

# username
dfx deploy username

# profile
dfx deploy profile

# projects
dfx deploy project_main

# snaps
dfx deploy snap_images
dfx deploy snap
dfx deploy snap_main

# logger
dfx deploy logger

# front end
dfx deploy dsign_assets

# killall dfx replica nodemanager