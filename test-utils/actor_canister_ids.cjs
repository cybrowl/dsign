const canister_ids = require('../.dfx/local/canister_ids.json');

const assets_file_chunks_canister_id = canister_ids.assets_file_chunks.local;
const assets_img_staging_canister_id = canister_ids.assets_img_staging.local;
const profile_canister_id = canister_ids.profile.local;
const project_main_canister_id = canister_ids.project_main.local;
const snap_main_canister_id = canister_ids.snap_main.local;
const test_assets_canister_id = canister_ids.test_assets.local;
const test_image_assets_canister_id = canister_ids.test_image_assets.local;
const test_project_canister_id = canister_ids.test_project.local;

module.exports = {
	assets_file_chunks_canister_id,
	assets_img_staging_canister_id,
	profile_canister_id,
	project_main_canister_id,
	snap_main_canister_id,
	test_assets_canister_id,
	test_image_assets_canister_id,
	test_project_canister_id
};
