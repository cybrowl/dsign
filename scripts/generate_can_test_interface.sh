#!/bin/bash

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

canisters=(
"assets_file_staging"
"assets_img_staging"
"canister_ids_ledger"
"explore"
"favorite_main"
"logger"
"profile"
"project_main"
"snap_main"
"test_assets"
"test_image_assets"
"test_project"
"test_snap",
"username_registry"
)

for canister in ${canisters[@]}; do
    cp .dfx/local/canisters/${canister}/service.did.js .dfx/local/canisters/${canister}/service.did.test.cjs
    sed -i '' 's/export//g' .dfx/local/canisters/${canister}/service.did.test.cjs
    echo "module.exports = { idlFactory };" >> .dfx/local/canisters/${canister}/service.did.test.cjs
done

