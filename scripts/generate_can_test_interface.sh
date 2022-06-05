#!/bin/bash

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

# account_settings
cp .dfx/local/canisters/account_settings/account_settings.did.js .dfx/local/canisters/account_settings/account_settings.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/account_settings/account_settings.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/account_settings/account_settings.did.test.cjs

# logger
cp .dfx/local/canisters/logger/logger.did.js .dfx/local/canisters/logger/logger.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/logger/logger.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/logger/logger.did.test.cjs

# profile_avatar
cp .dfx/local/canisters/profile_avatar/profile_avatar.did.js .dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs

# project_main
cp .dfx/local/canisters/project_main/project_main.did.js .dfx/local/canisters/project_main/project_main.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/project_main/project_main.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/project_main/project_main.did.test.cjs

# snap
cp .dfx/local/canisters/snap/snap.did.js .dfx/local/canisters/snap/snap.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/snap/snap.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/snap/snap.did.test.cjs

# snap_images
cp .dfx/local/canisters/snap_images/snap_images.did.js .dfx/local/canisters/snap_images/snap_images.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/snap_images/snap_images.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/snap_images/snap_images.did.test.cjs

# snap_main
cp .dfx/local/canisters/snap_main/snap_main.did.js .dfx/local/canisters/snap_main/snap_main.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/snap_main/snap_main.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/snap_main/snap_main.did.test.cjs

# username
cp .dfx/local/canisters/username/username.did.js .dfx/local/canisters/username/username.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/username/username.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/username/username.did.test.cjs