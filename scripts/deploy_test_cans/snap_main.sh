export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)
export PROJECT_MAIN_PRINCIPAL=$(dfx canister id project_main)

# deploy
dfx deploy test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy test_snap --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", principal "'${PROJECT_MAIN_PRINCIPAL}'")'
dfx deploy snap_main

# check version
dfx canister call test_assets version
dfx canister call test_image_assets version
dfx canister call test_snap version
dfx canister call snap_main version

# generate test interface
npm run generate_test_interface

# GENERATE WASM FOR NETWORK IC
# dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", true)'
# dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", true)'
# dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_snap --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", principal "'${PROJECT_MAIN_PRINCIPAL}'")'