const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const {
	idlFactory: profile_interface
} = require('../.dfx/local/canisters/profile/profile.did.test.cjs');

// Canister Ids
const canister_ids = require('../.dfx/local/canister_ids.json');
const profile_canister_id = canister_ids.profile.local;

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();
let motoko_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let mishicat_profile_actor = null;
let motoko_profile_actor = null;

test('Profile.version()', async function (t) {
	mishicat_profile_actor = await get_actor(
		profile_canister_id,
		profile_interface,
		mishicat_identity
	);

	motoko_profile_actor = await get_actor(
		profile_canister_id,
		profile_interface,
		motoko_identity
	);

	const response = await mishicat_profile_actor.version();

	console.log('=========== Profile ===========');
	console.log('version: ', response);
});
