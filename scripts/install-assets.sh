export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)

# dfx deploy test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'")'
dfx deploy test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", false)'
dfx canister call test_image_assets version
npm run generate_test_interface
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'", true)'