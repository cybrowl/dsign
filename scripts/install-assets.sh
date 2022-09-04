export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)

dfx deploy test_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'")'
dfx deploy test_image_assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'")'