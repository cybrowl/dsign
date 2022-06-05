#!/bin/bash

npm install

dfx stop
dfx start --background --clean

# account settings
dfx deploy account_settings
export ACCOUNT_SETTINGS_ID=$(dfx canister id account_settings)

dfx deploy profile_avatar
export PROFILE_AVATAR_ID=$(dfx canister id profile_avatar)

dfx deploy profile --argument '("'${ACCOUNT_SETTINGS_ID}'", "'${PROFILE_AVATAR_ID}'")'

# projects
dfx deploy project_main

# snaps
sh ./install-snaps.sh

# logger
dfx deploy logger

# front end
dfx deploy dsign_assets