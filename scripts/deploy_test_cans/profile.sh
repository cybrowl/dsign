export PROFILE_PRINCIPAL=$(dfx canister id profile)

# GENERATE WASM FOR LOCAL

dfx deploy test_image_assets --argument='(principal "'${PROFILE_PRINCIPAL}'", false)'

dfx deploy profile