#!/bin/bash

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

canisters=(
"explore"
"logger"
"creator"
"username_registry"
)

for canister in ${canisters[@]}; do
    cp .dfx/local/canisters/${canister}/service.did.js .dfx/local/canisters/${canister}/service.did.test.cjs
    sed -i '' 's/export//g' .dfx/local/canisters/${canister}/service.did.test.cjs
    echo "module.exports = { idlFactory };" >> .dfx/local/canisters/${canister}/service.did.test.cjs
done

