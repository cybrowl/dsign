export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)
export PROFILE_PRINCIPAL=$(dfx canister id profile)
export PROJECT_MAIN_PRINCIPAL=$(dfx canister id project_main)

# GENERATE WASM FOR LOCAL

dfx deploy test_project --argument='(principal "'${PROJECT_MAIN_PRINCIPAL}'", false)'

dfx deploy project_main

dfx canister call test_project version

npm run generate_test_interface