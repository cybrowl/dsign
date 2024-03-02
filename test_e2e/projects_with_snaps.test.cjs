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
const { parseIdentity } = require('./actor_identity.cjs');

let nikola_identity = parseIdentity(process.env.NIKOLA_IDENTITY);
let linky_identity = parseIdentity(process.env.LINKY_IDENTITY);
let anonymous_identity = null;

// Utils
const { getActor: get_actor } = require('./actor.cjs');

let username_registry_actor = {};
let project_id = '';

test('Setup Actors', async function () {
	console.log('=========== Project With Snaps ===========');

	// Username Registry
	username_registry_actor.nikola = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		nikola_identity
	);
	username_registry_actor.linky = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		linky_identity
	);
	username_registry_actor.anonymous = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		anonymous_identity
	);
});

test('UsernameRegistry[nikola].version(): => #ok - Nat', async function (t) {
	const version_num = await username_registry_actor.nikola.version();

	t.assert(version_num === 1n, 'Correct Version');
	t.end();
});

test('UsernameRegistry[nikola].delete_profile(): with valid principal => #ok - Bool', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.nikola.create_profile('nikola');

	const { ok: deleted, err: _ } = await username_registry_actor.nikola.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[linky].delete_profile(): with valid principal => #ok - Bool', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.linky.create_profile('linky');

	const { ok: deleted, err: _ } = await username_registry_actor.linky.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[nikola].create_profile(): with valid username => #ok - Username', async function (t) {
	const { ok: username, err: _ } = await username_registry_actor.nikola.create_profile('nikola');

	t.assert(username.length > 2, 'Created Profile');
	t.end();
});

test('UsernameRegistry[linky].create_profile(): with valid username => #ok - Username', async function (t) {
	const { ok: username, err: _ } = await username_registry_actor.linky.create_profile('linky');

	t.assert(username.length > 2, 'Created Profile');
});

test('Creator[nikola].create_project(): with valid args => #ok - ProjectPublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.nikola.get_info_by_username('nikola');

	const creator_actor_nikola = await get_actor(
		username_info.canister_id,
		creator_interface,
		nikola_identity
	);

	const { ok: project } = await creator_actor_nikola.create_project({
		name: 'Project One',
		description: ['first project']
	});

	project_id = project.id;

	t.ok(project, 'Project creation response should be ok');
	t.equal(project.name, 'Project One', 'Project name should match');
	t.deepEqual(project.description, ['first project'], 'Project description should match');
	t.end();
});
