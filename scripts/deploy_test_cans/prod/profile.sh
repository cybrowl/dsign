export PROFILE_PRINCIPAL=$(dfx canister --network ic id profile)

# GENERATE WASM FOR LOCAL

# deploy
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai test_image_assets --argument='(principal "'${PROFILE_PRINCIPAL}'", true)'
dfx deploy --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai profile

# check version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call test_image_assets version
dfx canister --network=ic --wallet=l2eht-qyaaa-aaaag-aaarq-cai call profile version

# generate test interface
npm run generate_test_interface
