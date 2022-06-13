#!/bin/bash

# username
dfx deploy username

# profile_avatar
dfx deploy profile_avatar_images
# export PROFILE_AVATAR_ID=$(dfx canister id profile_avatar)

dfx deploy profile_avatar_main

# profile
dfx deploy profile

# projects
# dfx deploy project_main

# snaps
dfx deploy snap_images
dfx deploy snap
dfx deploy snap_main

# logger
dfx deploy logger

# front end
dfx deploy dsign_assets

# killall dfx replica nodemanager