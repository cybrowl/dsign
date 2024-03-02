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

let owl_identity = parseIdentity(process.env.OWL_IDENTITY);
let dominic_identity = parseIdentity(process.env.DOMINIC_IDENTITY);
let anonymous_identity = null;

// Utils
const { getActor: get_actor } = require('./actor.cjs');

let username_registry_actor = {};
let project_id = '';

test('Setup Actors', async function () {
	console.log('=========== Profile Creation ===========');

	// Username Registry
	username_registry_actor.owl = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		owl_identity
	);
	username_registry_actor.dominic = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		dominic_identity
	);
	username_registry_actor.anonymous = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		anonymous_identity
	);
});

test('UsernameRegistry[owl].version(): => #ok - Nat', async function (t) {
	const version_num = await username_registry_actor.owl.version();

	t.assert(version_num === 1n, 'Correct Version');
	t.end();
});

test('UsernameRegistry[owl].delete_profile(): with valid principal => #ok - Bool', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.owl.create_profile('owl');

	const { ok: deleted, err: _ } = await username_registry_actor.owl.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[dominic].delete_profile(): with valid principal => #ok - Bool', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.dominic.create_profile('dominic');

	const { ok: deleted, err: _ } = await username_registry_actor.dominic.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[owl].create_profile(): with valid username => #ok - Username', async function (t) {
	const { ok: username, err: _ } = await username_registry_actor.owl.create_profile('owl');

	t.assert(username.length > 2, 'Created Profile');
	t.end();
});

test('UsernameRegistry[dominic].create_profile(): with valid username => #ok - Username', async function (t) {
	const { ok: username, err: _ } = await username_registry_actor.dominic.create_profile('dominic');

	t.assert(username.length > 2, 'Created Profile');
});

test('Creator[owl].total_users(): => #ok - NumberOfUsers', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const users_total = await creator_actor_owl.total_users();

	t.assert(users_total > 0, 'Has Created User');
	t.end();
});

test('Creator[owl].create_project(): with valid args => #ok - ProjectPublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const { ok: project } = await creator_actor_owl.create_project({
		name: 'Project One',
		description: ['first project']
	});

	project_id = project.id;

	t.ok(project, 'Project creation response should be ok');
	t.equal(project.name, 'Project One', 'Project name should match');
	t.deepEqual(project.description, ['first project'], 'Project description should match');
	t.end();
});

test('Creator[owl].get_project(): with valid id => #ok - ProjectPublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const { ok: project } = await creator_actor_owl.get_project(project_id);

	t.ok(project, 'Project creation response should be ok');
	t.equal(project.name, 'Project One', 'Project name should match');
	t.deepEqual(project.description, ['first project'], 'Project description should match');
	t.end();
});

test('Creator[owl].get_profile_by_username(): with valid username => #ok - ProfilePublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const { ok: profile } = await creator_actor_owl.get_profile_by_username(username_info.username);

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

test('Creator[owl].update_project(): with no optional args => #ok - ProjectPublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const { ok: project } = await creator_actor_owl.update_project({
		id: project_id,
		name: [],
		description: []
	});

	t.ok(project, 'Project creation response should be ok');
	t.equal(project.name, 'Project One', 'Project name should match');
	t.deepEqual(project.description, ['first project'], 'Project description should match');
	t.end();
});

test('Creator[owl].update_project(): with name only => #ok - ProjectPublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const { ok: project } = await creator_actor_owl.update_project({
		id: project_id,
		name: ['Project One Updated'],
		description: []
	});

	t.ok(project, 'Project creation response should be ok');
	t.equal(project.name, 'Project One Updated', 'Project name should match');
	t.deepEqual(project.description, ['first project'], 'Project description should match');
	t.end();
});

test('Creator[owl].update_project(): with description only => #ok - ProjectPublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const { ok: project } = await creator_actor_owl.update_project({
		id: project_id,
		name: [],
		description: ['first project updated']
	});

	t.ok(project, 'Project creation response should be ok');
	t.equal(project.name, 'Project One Updated', 'Project name should match');
	t.deepEqual(project.description, ['first project updated'], 'Project description should match');
	t.end();
});

test('Creator[owl].delete_project(): with valid id => #ok - Bool', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const { ok: deleted } = await creator_actor_owl.delete_project(project_id);

	t.assert(deleted === true, 'Deleted Project');

	t.end();
});

test('Creator[owl].get_project(): with invalid id => #err - ProjectNotFound', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const { err: error } = await creator_actor_owl.get_project(project_id);

	t.deepEqual(error, { ProjectNotFound: true });
	t.end();
});

test('Creator[owl].get_profile_by_username(): with valid username => #ok - ProfilePublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.owl.get_info_by_username('owl');

	const creator_actor_owl = await get_actor(
		username_info.canister_id,
		creator_interface,
		owl_identity
	);

	const { ok: profile } = await creator_actor_owl.get_profile_by_username(username_info.username);

	t.ok(profile.projects.length === 0, 'Profile should have zero projects');
	t.end();
});
