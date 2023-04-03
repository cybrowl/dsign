#!/bin/bash

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

# assets_file_staging
cp .dfx/local/canisters/assets_file_staging/assets_file_staging.did.js .dfx/local/canisters/assets_file_staging/assets_file_staging.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/assets_file_staging/assets_file_staging.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/assets_file_staging/assets_file_staging.did.test.cjs

# assets_img_staging
cp .dfx/local/canisters/assets_img_staging/assets_img_staging.did.js .dfx/local/canisters/assets_img_staging/assets_img_staging.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/assets_img_staging/assets_img_staging.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/assets_img_staging/assets_img_staging.did.test.cjs

# canister_ids_ledger
cp .dfx/local/canisters/canister_ids_ledger/canister_ids_ledger.did.js .dfx/local/canisters/canister_ids_ledger/canister_ids_ledger.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/canister_ids_ledger/canister_ids_ledger.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/canister_ids_ledger/canister_ids_ledger.did.test.cjs

# explore
cp .dfx/local/canisters/explore/explore.did.js .dfx/local/canisters/explore/explore.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/explore/explore.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/explore/explore.did.test.cjs

# favorite_main
cp .dfx/local/canisters/favorite_main/favorite_main.did.js .dfx/local/canisters/favorite_main/favorite_main.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/favorite_main/favorite_main.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/favorite_main/favorite_main.did.test.cjs

# health_metrics
cp .dfx/local/canisters/health_metrics/health_metrics.did.js .dfx/local/canisters/health_metrics/health_metrics.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/health_metrics/health_metrics.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/health_metrics/health_metrics.did.test.cjs

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