const {
	idlFactory: assets_img_staging_interface
} = require('../.dfx/local/canisters/assets_img_staging/assets_img_staging.did.test.cjs');
const {
	idlFactory: assets_file_chunks_interface
} = require('../.dfx/local/canisters/assets_file_chunks/assets_file_chunks.did.test.cjs');
const {
	idlFactory: profile_interface
} = require('../.dfx/local/canisters/profile/profile.did.test.cjs');
const {
	idlFactory: snap_main_interface
} = require('../.dfx/local/canisters/snap_main/snap_main.did.test.cjs');
const {
	idlFactory: test_assets_interface
} = require('../.dfx/local/canisters/test_assets/test_assets.did.test.cjs');
const {
	idlFactory: username_interface
} = require('../.dfx/local/canisters/username/username.did.test.cjs');

module.exports = {
	assets_file_chunks_interface,
	assets_img_staging_interface,
	profile_interface,
	snap_main_interface,
	test_assets_interface,
	username_interface
};
