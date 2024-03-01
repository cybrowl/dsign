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
let project_id = '';

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

test('UsernameRegistry[mishicat].version(): => #ok - Nat', async function (t) {
	const version_num = await username_registry_actor.mishicat.version();

	t.assert(version_num === 1n, 'Correct Version');
	t.end();
});

test('UsernameRegistry[mishicat].delete_profile(): with valid principal => #ok - Bool', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.mishicat.create_profile('mishicat');

	const { ok: deleted, err: _ } = await username_registry_actor.mishicat.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[motoko].delete_profile(): with valid principal => #ok - Bool', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.motoko.create_profile('motoko');

	const { ok: deleted, err: _ } = await username_registry_actor.motoko.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[mishicat].create_profile(): with valid username => #ok - Username', async function (t) {
	const { ok: username, err: _ } =
		await username_registry_actor.mishicat.create_profile('mishicat');

	t.assert(username.length > 2, 'Created Profile');
	t.end();
});

test('UsernameRegistry[motoko].create_profile(): with valid username => #ok - Username', async function (t) {
	const { ok: username, err: _ } = await username_registry_actor.motoko.create_profile('motoko');

	t.assert(username.length > 2, 'Created Profile');
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
	t.end();
});

test('Creator[mishicat].create_project(): with valid args => #ok - ProjectPublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { ok: project } = await creator_actor_mishicat.create_project({
		name: 'Project One',
		description: ['first project']
	});

	project_id = project.id;

	t.ok(project, 'Project creation response should be ok');
	t.equal(project.name, 'Project One', 'Project name should match');
	t.deepEqual(project.description, ['first project'], 'Project description should match');
	t.end();
});

test('Creator[mishicat].get_project(): with valid id => #ok - ProjectPublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { ok: project } = await creator_actor_mishicat.get_project(project_id);

	t.ok(project, 'Project creation response should be ok');
	t.equal(project.name, 'Project One', 'Project name should match');
	t.deepEqual(project.description, ['first project'], 'Project description should match');
	t.end();
});

test('Creator[mishicat].get_profile_by_username(): with valid username => #ok - ProfilePublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { ok: profile } = await creator_actor_mishicat.get_profile_by_username(
		username_info.username
	);

	t.ok(profile.projects.length > 0, 'Profile should have at least one project');
	t.equal(profile.projects[0].name, 'Project One', 'The project name should match expected value');
	t.ok(
		typeof profile.projects[0].canister_id === 'string' &&
			profile.projects[0].canister_id.length > 0,
		'Project canister ID should be a non-empty string'
	);

	const pattern = /^[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[cai]{3}$/;
	t.ok(
		pattern.test(profile.projects[0].canister_id),
		'Project canister ID should match the expected format'
	);

	t.ok(profile.is_owner, 'Profile should indicate ownership');
	t.end();
});

test('Creator[mishicat].delete_project(): with valid id => #ok - Bool', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { ok: deleted } = await creator_actor_mishicat.delete_project(project_id);

	t.assert(deleted === true, 'Deleted Project');

	t.end();
});

test('Creator[mishicat].get_project(): with invalid id => #err - ProjectNotFound', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { err: error } = await creator_actor_mishicat.get_project(project_id);

	t.deepEqual(error, { ProjectNotFound: true });
	t.end();
});

test('Creator[mishicat].get_profile_by_username(): with valid username => #ok - ProfilePublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.mishicat.get_info_by_username('mishicat');

	const creator_actor_mishicat = await get_actor(
		username_info.canister_id,
		creator_interface,
		mishicat_identity
	);

	const { ok: profile } = await creator_actor_mishicat.get_profile_by_username(
		username_info.username
	);

	t.ok(profile.projects.length === 0, 'Profile should have zero projects');
	t.end();
});
