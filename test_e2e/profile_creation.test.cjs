const test = require('tape');
const { config } = require('dotenv');

config();

// Actor Interface
const {
	creator_interface,
	username_registry_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const { username_registry_canister_id } = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { parseIdentity } = require('../test-utils/identities/identity.cjs');

let mishicat_identity = parseIdentity(process.env.MISHICAT_IDENTITY);
let anonymous_identity = null;

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

test('UsernameRegistry[mishicat].get_username(): with invalid principal => #err - UserPrincipalNotFound', async function (t) {
	const { ok: _, err: err_username } = await username_registry_actor.mishicat.get_username();

	t.deepEqual(err_username, { UserPrincipalNotFound: true });
});

test('UsernameRegistry[mishicat].get_username_info(): with invalid unsername => #err - UsernameNotFound', async function (t) {
	const { ok: _, err: err_username } =
		await username_registry_actor.mishicat.get_username_info('mishicat');

	t.deepEqual(err_username, { UsernameNotFound: true });
});

test('UsernameRegistry[anonymous].create_profile(): with anon identity => #err - CallerAnonymous', async function (t) {
	const { ok: _, err: err_profile } =
		await username_registry_actor.anonymous.create_profile('mishicat');

	t.deepEqual(err_profile, { CallerAnonymous: true });
});

test('UsernameRegistry[mishicat].create_profile(): with invalid username => #err - UsernameInvalid', async function (t) {
	const { ok: _, err: err_profile } =
		await username_registry_actor.mishicat.create_profile('Mishicat');

	t.deepEqual(err_profile, { UsernameInvalid: true });
});

test('UsernameRegistry[mishicat].create_profile(): with valid username => #ok - Created Profile', async function (t) {
	const { ok: username, err: _ } =
		await username_registry_actor.mishicat.create_profile('mishicat');

	t.assert(username.length > 2, 'Created Profile');
});

test('UsernameRegistry[mishicat].create_profile(): with taken username => #ok - UsernameTaken', async function (t) {
	const { ok: _, err: err_profile } =
		await username_registry_actor.mishicat.create_profile('mishicat');

	t.deepEqual(err_profile, { UsernameTaken: true });
});

test('Creator[mishicat].total_users(): => #ok - NumberOfUsers', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_username_info('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const users_total = await creator_actor_mishicat.total_users();

	t.assert(users_total > 0, 'Has Created User');
});

test('Creator[mishicat].get_profile(): => #ok - Profile', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_username_info('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { ok: profile, err: _err } = await creator_actor_mishicat.get_profile();

	t.equal(profile.username, 'mishicat', 'Username matches expected');
	t.equal(profile.storage_mb_used, 0n, 'Storage used matches expected');
	t.deepEqual(profile.projects, [], 'Projects array is empty as expected');
	t.ok(profile.banner.exists === false, 'Banner exists flag matches expected');
	t.equal(profile.banner.url, '/default_profile_banner.png', 'Banner URL matches expected');
});

test('Creator[anonymous].get_profile(): => #err - ProfileNotFound', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_username_info('mishicat');

	const creator_actor_anonymous = await get_actor(
		username_info.canister_id,
		creator_interface,
		anonymous_identity
	);

	const { ok: _ok, err: err_profile } = await creator_actor_anonymous.get_profile();

	t.deepEqual(err_profile, { ProfileNotFound: true });
});
