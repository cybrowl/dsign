export PROFILE_PRINCIPAL=$(dfx canister id profile)

# GENERATE WASM FOR LOCAL

# deploy
dfx deploy test_image_assets --argument='(principal "'${PROFILE_PRINCIPAL}'", false)'
dfx deploy profile

# check version
dfx canister call test_image_assets version
dfx canister call profile version

# generate test interface
npm run generate_test_interface