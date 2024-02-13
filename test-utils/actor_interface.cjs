function getInterface(canister) {
	const { idlFactory } = require(`../.dfx/local/canisters/${canister}/service.did.test.cjs`);
	return idlFactory;
}

module.exports = {
	assets_file_staging_interface: getInterface('assets_file_staging'),
	assets_img_staging_interface: getInterface('assets_img_staging'),
	canister_ids_ledger_interface: getInterface('canister_ids_ledger'),
	explore_interface: getInterface('explore'),
	favorite_main_interface: getInterface('favorite_main'),
	profile_interface: getInterface('profile'),
	project_main_interface: getInterface('project_main'),
	snap_main_interface: getInterface('snap_main'),
	test_assets_interface: getInterface('test_assets'),
	test_image_assets_interface: getInterface('test_image_assets'),
	test_project_interface: getInterface('test_project'),
	creator_interface: getInterface('creator'),
	username_registry_interface: getInterface('username_registry')
};
