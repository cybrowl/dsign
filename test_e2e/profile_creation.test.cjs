const test = require('tape');
const { config } = require('dotenv');

config();

// Actor Interface
const { username_registry_interface } = require('../test-utils/actor_interface.cjs');

// Canister Ids
const { username_registry_canister_id } = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { parseIdentity } = require('../test-utils/identities/identity.cjs');

let mishicat_identity = parseIdentity(process.env.MISHICAT_IDENTITY);

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let username_registry_actor = {};

test('Setup Actors', async function () {
	console.log('=========== Profile Creation ===========');

	// Username Registry
	username_registry_actor.mishicat = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		mishicat_identity
	);
});

test('UsernameRegistry[mishicat].version(): => #ok - Version Number', async function (t) {
	const version_num = await username_registry_actor.mishicat.version();

	t.assert(version_num === 1n, 'Correct Version');
	t.end();
});

test('UsernameRegistry[mishicat].get_username(): with invalid unsername => #err - UserPrincipalNotFound', async function (t) {});
