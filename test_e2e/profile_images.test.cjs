const test = require('tape');
const { config } = require('dotenv');

config();

// Actor Interface
const {
	creator_interface,
	username_registry_interface,
	file_scaling_manager_interface
} = require('../canister_refs/actor_interface.cjs');

// Canister Ids
const {
	username_registry_canister_id,
	file_scaling_manager_canister_id
} = require('../canister_refs/actor_canister_ids.cjs');

// Identities
const { parseIdentity } = require('../test-utils/identities/identity.cjs');

let mishicat_identity = parseIdentity(process.env.MISHICAT_IDENTITY);
let motoko_identity = parseIdentity(process.env.MOTOKO_IDENTITY);
let anonymous_identity = null;

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let username_registry_actor = {};
let file_scaling_manager_actor = {};

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

	// File Scaling Manager
	file_scaling_manager_actor.mishicat = await get_actor(
		file_scaling_manager_canister_id,
		file_scaling_manager_interface,
		mishicat_identity
	);
	file_scaling_manager_actor.motoko = await get_actor(
		file_scaling_manager_canister_id,
		file_scaling_manager_interface,
		motoko_identity
	);
	file_scaling_manager_actor.anonymous = await get_actor(
		file_scaling_manager_canister_id,
		file_scaling_manager_interface,
		anonymous_identity
	);
});

test('UsernameRegistry[mishicat].version(): => #ok - Version Number', async function (t) {
	const version_num = await username_registry_actor.mishicat.version();

	t.assert(version_num === 1n, 'Correct Version');
	t.end();
});

test('FileScalingManager[mishicat].version(): => #ok - Version Number', async function (t) {
	const version_num = await file_scaling_manager_actor.mishicat.version();

	t.assert(version_num === 1n, 'Correct Version');
	t.end();
});

test('FileScalingManager[mishicat].init(): => #err - FileStorageCanisterIdExists', async function (t) {
	const { ok: canister_id, err: error } = await file_scaling_manager_actor.mishicat.init();

	if (canister_id) {
		console.log('please run `npm run deploy or call init func in file_scaling_manager_actor`');
	}

	t.deepEqual(error, { FileStorageCanisterIdExists: true });
	t.end();
});

test('FileScalingManager[mishicat].get_file_storage_canister_id(): => #ok - CanisterId', async function (t) {
	const canister_id = await file_scaling_manager_actor.mishicat.get_file_storage_canister_id();

	// Example regex for basic validation, adjust according to your expected format
	const pattern = /^[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[cai]{3}$/;
	const isValidFormat = pattern.test(canister_id);

	t.ok(isValidFormat, `Canister ID "${canister_id}" matches the expected format`);
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
