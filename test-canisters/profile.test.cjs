const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const { profile_interface } = require('../test-utils/actor_interface.cjs');

// Canister Ids
const { profile_canister_id } = require('../test-utils/actor_canister_ids.cjs');

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();
let motoko_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let profile_actor = {};

test('Setup Actors', async function (t) {
	profile_actor.mishicat = await get_actor(
		profile_canister_id,
		profile_interface,
		mishicat_identity
	);

	profile_actor.motoko = await get_actor(profile_canister_id, profile_interface, motoko_identity);
});
