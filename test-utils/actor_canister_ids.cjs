const canister_ids = require('../.dfx/local/canister_ids.json');

const canisterNames = [
	'assets_file_staging',
	'assets_img_staging',
	'canister_ids_ledger',
	'explore',
	'favorite_main',
	'profile',
	'project_main',
	'snap_main',
	'test_assets',
	'test_image_assets',
	'test_project',
	'test_snap',
	'username_registry'
];

const ids = {};

for (const name of canisterNames) {
	ids[`${name}_canister_id`] = canister_ids[name].local;
}

module.exports = ids;
