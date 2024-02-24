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
	console.log('=========== Profile Creation ===========');

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

test('UsernameRegistry[motoko].delete_profile(): with valid principal => #ok - Deleted', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.motoko.create_profile('motoko');

	const { ok: deleted, err: _ } = await username_registry_actor.motoko.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[mishicat].get_username(): with invalid principal => #err - UserPrincipalNotFound', async function (t) {
	const { ok: _, err: err_username } = await username_registry_actor.mishicat.get_username();

	t.deepEqual(err_username, { UserPrincipalNotFound: true });
});

test('UsernameRegistry[mishicat].get_info_by_username(): with invalid unsername => #err - UsernameNotFound', async function (t) {
	const { ok: _, err: err_username } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

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

test('UsernameRegistry[motoko].create_profile(): with valid username => #ok - Created Profile', async function (t) {
	const { ok: username, err: _ } = await username_registry_actor.motoko.create_profile('motoko');

	t.assert(username.length > 2, 'Created Profile');
});

test('UsernameRegistry[mishicat].create_profile(): with taken username => #ok - UsernameTaken', async function (t) {
	const { ok: _, err: err_profile } =
		await username_registry_actor.mishicat.create_profile('mishicat');

	t.deepEqual(err_profile, { UsernameTaken: true });
});

test('Creator[mishicat].total_users(): => #ok - NumberOfUsers', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const users_total = await creator_actor_mishicat.total_users();

	t.assert(users_total > 0, 'Has Created User');
});

test('Creator[mishicat].get_profile_by_username(): with valid username & owner => #ok - Profile', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	// Assuming 'mishicat' is a valid username that was previously created
	const validUsername = 'mishicat';
	const creator_actor = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { ok: profile, err: errProfile } =
		await creator_actor.get_profile_by_username(validUsername);

	t.ok(profile, 'Successfully retrieved profile by username');
	t.equal(profile.username, validUsername, 'Retrieved profile username matches expected');
	t.equal(profile.is_owner, true, 'Owner of profile');
	t.deepEqual(profile.favorites, [], 'Favorites array is empty as expected');
	t.deepEqual(profile.projects, [], 'Projects array is empty as expected');
	t.deepEqual(profile.storage, [], 'Storage array is empty as expected');
	t.deepEqual(
		profile.banner,
		{ id: '', url: '/default_profile_banner.png', canister_id: '', exists: false },
		'Banner matches expected'
	);
	t.deepEqual(
		profile.avatar,
		{ id: '', url: '', canister_id: '', exists: false },
		'Avatar matches expected'
	);
	t.notOk(errProfile, 'No error when retrieving profile by valid username');
	t.end();
});

test('Creator[mishicat].get_profile_by_username(): with valid username & NOT owner => #ok - Profile', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	// Switch the identity to simulate a different user (not owner)
	// For this example, assume `mishicat_identity` represents the owner
	// and another identity is used for the "not owner" scenario.
	const validUsername = 'motoko';
	const creator_actor = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { ok: profile, err: errProfile } =
		await creator_actor.get_profile_by_username(validUsername);

	t.ok(profile, 'Successfully retrieved profile by username');
	t.equal(profile.username, validUsername, 'Retrieved profile username matches expected');
	t.equal(profile.is_owner, false, 'NOT Owner of profile');
	t.deepEqual(profile.favorites, [], 'Favorites array is empty as expected');
	t.deepEqual(profile.projects, [], 'Projects array is empty as expected');
	t.deepEqual(profile.storage, [], 'Storage array is empty as expected');
	t.deepEqual(
		profile.banner,
		{ id: '', url: '/default_profile_banner.png', canister_id: '', exists: false },
		'Banner matches expected'
	);
	t.deepEqual(
		profile.avatar,
		{ id: '', url: '', canister_id: '', exists: false },
		'Avatar matches expected'
	);
	t.notOk(errProfile, 'No error when retrieving profile by valid username');
	t.end();
});

test('Creator[mishicat].get_profile_by_username(): with invalid username => #err - ProfileNotFound', async function (t) {
	const { ok: username_info, err: _err } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	// Assuming 'nonexistentuser' is a username that does not exist
	const invalidUsername = 'nonexistentuser';
	const creator_actor = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { ok: _, err: errProfile } = await creator_actor.get_profile_by_username(invalidUsername);

	t.deepEqual(
		errProfile,
		{ ProfileNotFound: true },
		'Expected error when retrieving profile by invalid username'
	);
	t.end();
});

test('Creator[mishicat].get_canister_id(): => #ok - Canister ID', async function (t) {
	const { ok: username_info, err: _err } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const canisterId = await creator_actor_mishicat.get_canister_id();

	t.ok(
		typeof canisterId === 'string' && canisterId.length > 0,
		'Successfully retrieved non-empty canister ID'
	);
	t.end();
});

test('Creator[mishicat].get_canister_id(): => #ok - Format Check', async function (t) {
	const { ok: username_info, err: _err } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const canisterId = await creator_actor_mishicat.get_canister_id();

	// Example regex for basic validation, adjust according to your expected format
	const pattern = /^[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[cai]{3}$/;
	const isValidFormat = pattern.test(canisterId);

	t.ok(isValidFormat, `Canister ID "${canisterId}" matches the expected format`);
	t.end();
});
