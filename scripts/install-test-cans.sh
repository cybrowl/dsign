export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)
export PROJECT_MAIN_PRINCIPAL=$(dfx canister id project_main)

dfx deploy test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx deploy test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
# dfx deploy test_project --argument='(principal "'${PROJECT_MAIN_PRINCIPAL}'", false)'

dfx canister call test_assets version
dfx canister call test_image_assets version
dfx canister call test_project version

npm run generate_test_interface
# dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", true)'
# dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", true)'