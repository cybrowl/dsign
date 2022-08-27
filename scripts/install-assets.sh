export SNAP_MAIN_PRINCIPAL=$(dfx canister id snap_main)

dfx deploy assets --argument='(principal "'${SNAP_MAIN_PRINCIPAL}'")'
