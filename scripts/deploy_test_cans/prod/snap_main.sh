export SNAP_MAIN_PRINCIPAL=$(dfx canister --network ic id snap_main)
export PROJECT_MAIN_PRINCIPAL=$(dfx canister --network ic id project_main)
export FAVORITE_MAIN_PRINCIPAL=$(dfx canister --network ic id favorite_main)

# deploy
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", true)'
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", true)'
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_snap --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", principal "'${PROJECT_MAIN_PRINCIPAL}'"), principal "'${FAVORITE_MAIN_PRINCIPAL}'")'
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai snap_main

# check version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call test_assets version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call test_image_assets version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call test_snap version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call snap_main version

# generate test interface
npm run generate_test_interface

# GENERATE WASM FOR NETWORK IC
