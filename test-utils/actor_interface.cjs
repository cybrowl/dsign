function getInterface(canister) {
	const { idlFactory } = require(`../.dfx/local/canisters/${canister}/service.did.test.cjs`);
	return idlFactory;
}

module.exports = {
	explore_interface: getInterface('explore'),
	creator_interface: getInterface('creator'),
	username_registry_interface: getInterface('username_registry')
};
