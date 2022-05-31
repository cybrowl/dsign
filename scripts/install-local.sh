dfx stop
dfx start --background --clean

dfx deploy account_settings
export ACCOUNT_SETTINGS_ID=$(dfx canister id account_settings)

dfx deploy profile_avatar
export PROFILE_AVATAR_ID=$(dfx canister id profile_avatar)

dfx deploy projects
dfx deploy profile --argument '("'${ACCOUNT_SETTINGS_ID}'", "'${PROFILE_AVATAR_ID}'")'
dfx deploy snap_images
dfx deploy snaps
dfx deploy snap
dfx deploy logger
dfx deploy dsign_assets