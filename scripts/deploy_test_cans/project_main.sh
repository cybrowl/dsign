export PROJECT_MAIN_PRINCIPAL=$(dfx canister id project_main)

# GENERATE WASM FOR LOCAL

# deploy
dfx deploy test_project --argument='(principal "'${PROJECT_MAIN_PRINCIPAL}'", false)'
dfx deploy project_main

# check version
dfx canister call test_project version
dfx canister call project_main version

# generate test interface
npm run generate_test_interface