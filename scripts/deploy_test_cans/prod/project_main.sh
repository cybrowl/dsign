export PROJECT_MAIN_PRINCIPAL=$(dfx canister --network ic id project_main)

# GENERATE WASM FOR LOCAL

# deploy
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_project --argument='(principal "'${PROJECT_MAIN_PRINCIPAL}'", true)'
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai project_main

# check version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call test_project version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call project_main version

# generate test interface
npm run generate_test_interface