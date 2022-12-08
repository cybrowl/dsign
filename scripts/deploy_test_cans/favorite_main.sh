export FAVORITE_MAIN_PRINCIPAL=$(dfx canister id favorite_main)

# GENERATE WASM FOR LOCAL

# deploy
dfx deploy test_favorite --argument='(principal "'${FAVORITE_MAIN_PRINCIPAL}'")'
dfx deploy favorite_main

# check version
dfx canister call test_favorite version
dfx canister call favorite_main version

# generate test interface
npm run generate_test_interface