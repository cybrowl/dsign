export ASSETS_MAIN_PRINCIPAL=$(dfx canister id assets_main)

dfx deploy assets --argument='(principal "'${ASSETS_MAIN_PRINCIPAL}'")'
