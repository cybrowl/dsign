const {
	idlFactory: assets_img_staging_interface
} = require('../.dfx/local/canisters/assets_img_staging/assets_img_staging.did.test.cjs');
const {
	idlFactory: assets_file_chunks_interface
} = require('../.dfx/local/canisters/assets_file_chunks/assets_file_chunks.did.test.cjs');
const {
	idlFactory: canister_child_ledger_interface
} = require('../.dfx/local/canisters/canister_child_ledger/canister_child_ledger.did.test.cjs');
const {
	idlFactory: explore_interface
} = require('../.dfx/local/canisters/explore/explore.did.test.cjs');
const {
	idlFactory: favorite_main_interface
} = require('../.dfx/local/canisters/favorite_main/favorite_main.did.test.cjs');
const {
	idlFactory: health_metrics_interface
} = require('../.dfx/local/canisters/health_metrics/health_metrics.did.test.cjs');
const {
	idlFactory: profile_interface
} = require('../.dfx/local/canisters/profile/profile.did.test.cjs');
const {
	idlFactory: project_main_interface
} = require('../.dfx/local/canisters/project_main/project_main.did.test.cjs');
const {
	idlFactory: snap_main_interface
} = require('../.dfx/local/canisters/snap_main/snap_main.did.test.cjs');
const {
	idlFactory: test_assets_interface
} = require('../.dfx/local/canisters/test_assets/test_assets.did.test.cjs');
const {
	idlFactory: test_image_assets_interface
} = require('../.dfx/local/canisters/test_image_assets/test_image_assets.did.test.cjs');
const {
	idlFactory: test_project_interface
} = require('../.dfx/local/canisters/test_project/test_project.did.test.cjs');

module.exports = {
	assets_file_chunks_interface,
	assets_img_staging_interface,
	canister_child_ledger_interface,
	explore_interface,
	favorite_main_interface,
	health_metrics_interface,
	profile_interface,
	project_main_interface,
	snap_main_interface,
	test_assets_interface,
	test_image_assets_interface,
	test_project_interface
};
