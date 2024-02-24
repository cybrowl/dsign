const test = require('tape');
const { config } = require('dotenv');

config();

// Actor Interface
const {
	creator_interface,
	username_registry_interface
} = require('../canister_refs/actor_interface.cjs');

// Canister Ids
const { username_registry_canister_id } = require('../canister_refs/actor_canister_ids.cjs');

// Identities
const { parseIdentity } = require('../test-utils/identities/identity.cjs');

let mishicat_identity = parseIdentity(process.env.MISHICAT_IDENTITY);
let motoko_identity = parseIdentity(process.env.MOTOKO_IDENTITY);
let anonymous_identity = null;

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let username_registry_actor = {};

test('Setup Actors', async function () {
	console.log('=========== Profile Update Images ===========');

	// Username Registry
	username_registry_actor.mishicat = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		mishicat_identity
	);
	username_registry_actor.motoko = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		motoko_identity
	);
	username_registry_actor.anonymous = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		anonymous_identity
	);
});

test('UsernameRegistry[mishicat].version(): => #ok - Version Number', async function (t) {
	const version_num = await username_registry_actor.mishicat.version();

	t.assert(version_num === 1n, 'Correct Version');
	t.end();
});

test('UsernameRegistry[mishicat].initialize_canisters(): => #ok - CanisterId', async function (t) {
	const canister_id = await username_registry_actor.mishicat.initialize_canisters();

	t.assert(canister_id.length > 2, 'Correct Length');
	t.end();
});

test('UsernameRegistry[mishicat].delete_profile(): with valid principal => #ok - Deleted', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.mishicat.create_profile('mishicat');

	const { ok: deleted, err: _ } = await username_registry_actor.mishicat.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[mishicat].create_profile(): with valid username => #ok - Created Profile', async function (t) {
	const { ok: username, err: _ } =
		await username_registry_actor.mishicat.create_profile('mishicat');

	t.assert(username.length > 2, 'Created Profile');
});
