#!/bin/bash

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

# assets_file_chunks
cp .dfx/local/canisters/assets_file_chunks/assets_file_chunks.did.js .dfx/local/canisters/assets_file_chunks/assets_file_chunks.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/assets_file_chunks/assets_file_chunks.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/assets_file_chunks/assets_file_chunks.did.test.cjs

# assets_img_staging
cp .dfx/local/canisters/assets_img_staging/assets_img_staging.did.js .dfx/local/canisters/assets_img_staging/assets_img_staging.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/assets_img_staging/assets_img_staging.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/assets_img_staging/assets_img_staging.did.test.cjs

# logger
cp .dfx/local/canisters/logger/logger.did.js .dfx/local/canisters/logger/logger.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/logger/logger.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/logger/logger.did.test.cjs

# profile
cp .dfx/local/canisters/profile/profile.did.js .dfx/local/canisters/profile/profile.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/profile/profile.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/profile/profile.did.test.cjs

# project_main
cp .dfx/local/canisters/project_main/project_main.did.js .dfx/local/canisters/project_main/project_main.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/project_main/project_main.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/project_main/project_main.did.test.cjs

# snap_main
cp .dfx/local/canisters/snap_main/snap_main.did.js .dfx/local/canisters/snap_main/snap_main.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/snap_main/snap_main.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/snap_main/snap_main.did.test.cjs

# username
cp .dfx/local/canisters/username/username.did.js .dfx/local/canisters/username/username.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/username/username.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/username/username.did.test.cjs

# test_assets
cp .dfx/local/canisters/test_assets/test_assets.did.js .dfx/local/canisters/test_assets/test_assets.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/test_assets/test_assets.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/test_assets/test_assets.did.test.cjs

# test_image_assets
cp .dfx/local/canisters/test_image_assets/test_image_assets.did.js .dfx/local/canisters/test_image_assets/test_image_assets.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/test_image_assets/test_image_assets.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/test_image_assets/test_image_assets.did.test.cjs

# test_project
cp .dfx/local/canisters/test_project/test_project.did.js .dfx/local/canisters/test_project/test_project.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/test_project/test_project.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/test_project/test_project.did.test.cjs

# test_snap
cp .dfx/local/canisters/test_snap/test_snap.did.js .dfx/local/canisters/test_snap/test_snap.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/test_snap/test_snap.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/test_snap/test_snap.did.test.cjs