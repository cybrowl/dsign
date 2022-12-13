export FAVORITE_MAIN_PRINCIPAL=$(dfx canister --network ic id favorite_main)

# GENERATE WASM FOR LOCAL

# deploy
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_favorite --argument='(principal "'${FAVORITE_MAIN_PRINCIPAL}'")'
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai favorite_main

# check version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call test_favorite version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call favorite_main version

# generate test interface
npm run generate_test_interface