const test = require('tape');

const { Ed25519KeyIdentity } = require('@dfinity/identity');

// Actor Interface
const { project_main_interface } = require('../test-utils/actor_interface.cjs');

// Canister Ids
const { project_main_canister_id } = require('../test-utils/actor_canister_ids.cjs');

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let project_main_actor = {};

test('Setup Actors', async function (t) {
	console.log('=========== Project Main ===========');

	console.log('project_main_canister_id: ', project_main_canister_id);
	project_main_actor.mishicat = await get_actor(
		project_main_canister_id,
		project_main_interface,
		mishicat_identity
	);
});

test('ProjectMain[mishicat].initialize_canisters()', async function (t) {
	let response = await project_main_actor.mishicat.initialize_canisters([]);

	console.log('response', response);
});
