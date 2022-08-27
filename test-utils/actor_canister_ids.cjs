const canister_ids = require('../.dfx/local/canister_ids.json');

const assets_canister_id = canister_ids.assets.local;
const assets_file_chunks_canister_id = canister_ids.assets_file_chunks.local;
const snap_main_canister_id = canister_ids.snap_main.local;
const username_canister_id = canister_ids.username.local;

module.exports = {
	assets_canister_id,
	assets_file_chunks_canister_id,
	snap_main_canister_id,
	username_canister_id
};
