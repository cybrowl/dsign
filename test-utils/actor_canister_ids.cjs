const canister_ids = require('../.dfx/local/canister_ids.json');

const snap_main_canister_id = canister_ids.snap_main.local;
const username_canister_id = canister_ids.username.local;

module.exports = {
	snap_main_canister_id,
	username_canister_id
};
