// Require the necessary module for reading IDL factory files
const path = require('path');

const canisterNames = [
	'explore',
	'creator',
	'username_registry',
	'file_storage',
	'file_scaling_manager'
];

function getInterface(canister) {
	const idlFactoryPath = path.join(
		__dirname,
		`../.dfx/local/canisters/${canister}/service.did.test.cjs`
	);
	const { idlFactory } = require(idlFactoryPath);
	return idlFactory;
}

const interfaces = {};

for (const name of canisterNames) {
	interfaces[`${name}_interface`] = getInterface(name);
}

module.exports = interfaces;
