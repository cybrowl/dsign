#!/bin/bash

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

# profile_avatar
cp .dfx/local/canisters/profile_avatar/profile_avatar.did.js .dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs

# account_settings
cp .dfx/local/canisters/account_settings/account_settings.did.js .dfx/local/canisters/account_settings/account_settings.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/account_settings/account_settings.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/account_settings/account_settings.did.test.cjs

# projects
cp .dfx/local/canisters/projects/projects.did.js .dfx/local/canisters/projects/projects.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/projects/projects.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/projects/projects.did.test.cjs

# snap
cp .dfx/local/canisters/snap/snap.did.js .dfx/local/canisters/snap/snap.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/snap/snap.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/snap/snap.did.test.cjs

# snap_images
cp .dfx/local/canisters/snap_images/snap_images.did.js .dfx/local/canisters/snap_images/snap_images.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/snap_images/snap_images.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/snap_images/snap_images.did.test.cjs

# snaps
cp .dfx/local/canisters/snaps/snaps.did.js .dfx/local/canisters/snaps/snaps.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/snaps/snaps.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/snaps/snaps.did.test.cjs

# snap_images
cp .dfx/local/canisters/snap_images/snap_images.did.js .dfx/local/canisters/snap_images/snap_images.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/snap_images/snap_images.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/snap_images/snap_images.did.test.cjs

# logger
cp .dfx/local/canisters/logger/logger.did.js .dfx/local/canisters/logger/logger.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/logger/logger.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/logger/logger.did.test.cjs