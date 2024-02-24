const canister_ids = require('../.dfx/local/canister_ids.json');

const canisterNames = ['explore', 'creator', 'username_registry'];

const ids = {};

for (const name of canisterNames) {
	ids[`${name}_canister_id`] = canister_ids[name].local;
}

module.exports = ids;
