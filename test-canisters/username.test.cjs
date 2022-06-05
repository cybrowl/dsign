const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const {
	idlFactory: username_interface
} = require('../.dfx/local/canisters/username/username.did.test.cjs');

// Canister Ids
const canister_ids = require('../.dfx/local/canister_ids.json');
const snap_images_canister_id = canister_ids.username.local;

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let snap_images_actor = null;

test('Username.version()', async function (t) {
	snap_images_actor = await get_actor(
		snap_images_canister_id,
		username_interface,
		mishicat_identity
	);

	const response = await snap_images_actor.version();

	console.log('=========== Snaps Images ===========');
	console.log('version: ', response);
});
