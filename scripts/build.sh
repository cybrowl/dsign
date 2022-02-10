#!/bin/bash

# DFX BUILD #
## stop
# dfx stop

# ## start clean
# dfx start --clean --background

# ## register canister identifiers
# dfx canister create --all

# ## build
# dfx build

# ## install 
# dfx canister install --all

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

# profile_avatar
cp .dfx/local/canisters/profile_avatar/profile_avatar.did.js .dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs

# profile_manager
cp .dfx/local/canisters/profile_manager/profile_manager.did.js .dfx/local/canisters/profile_manager/profile_manager.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/profile_manager/profile_manager.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/profile_manager/profile_manager.did.test.cjs

# logger
cp .dfx/local/canisters/logger/logger.did.js .dfx/local/canisters/logger/logger.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/logger/logger.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/logger/logger.did.test.cjs