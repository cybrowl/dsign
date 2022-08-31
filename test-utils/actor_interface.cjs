const {
	idlFactory: assets_img_staging_interface
} = require('../.dfx/local/canisters/assets_img_staging/assets_img_staging.did.test.cjs');
const {
	idlFactory: assets_file_chunks_interface
} = require('../.dfx/local/canisters/assets_file_chunks/assets_file_chunks.did.test.cjs');
const {
	idlFactory: snap_main_interface
} = require('../.dfx/local/canisters/snap_main/snap_main.did.test.cjs');
const {
	idlFactory: username_interface
} = require('../.dfx/local/canisters/username/username.did.test.cjs');

module.exports = {
	assets_file_chunks_interface,
	assets_img_staging_interface,
	snap_main_interface,
	username_interface
};
