const {
	idlFactory: snap_main_interface
} = require('../.dfx/local/canisters/snap_main/snap_main.did.test.cjs');
const {
	idlFactory: username_interface
} = require('../.dfx/local/canisters/username/username.did.test.cjs');

module.exports = {
	snap_main_interface,
	username_interface
};
