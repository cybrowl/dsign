const test = require('tape');
const { config } = require('dotenv');

config();

// Actor Interface
const {
	assets_img_staging_interface,
	project_main_interface,
	test_project_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	assets_img_staging_canister_id,
	project_main_canister_id,
	test_project_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { parseIdentity } = require('../test-utils/identities/identity.cjs');

let mishicat_identity = parseIdentity(process.env.MISHICAT_IDENTITY);
let motoko_identity = parseIdentity(process.env.MOTOKO_IDENTITY);
let default_identity = parseIdentity(process.env.DEFAULT_IDENTITY);

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let assets_img_staging_actors = {};
let project_actor = {};
let project_main_actor = {};
let project_info = {};

test('Setup Actors', async function () {
	console.log('=========== Project Main ===========');

	console.log('project_main_canister_id: ', project_main_canister_id);

	assets_img_staging_actors.mishicat = await get_actor(
		assets_img_staging_canister_id,
		assets_img_staging_interface,
		mishicat_identity
	);

	project_main_actor.mishicat = await get_actor(
		project_main_canister_id,
		project_main_interface,
		mishicat_identity
	);

	project_main_actor.motoko = await get_actor(
		project_main_canister_id,
		project_main_interface,
		motoko_identity
	);

	project_main_actor.default = await get_actor(
		project_main_canister_id,
		project_main_interface,
		default_identity
	);

	project_actor.mishicat = await get_actor(
		test_project_canister_id,
		test_project_interface,
		mishicat_identity
	);
});

test('ProjectMain[default].get_all_projects(): when user has zero projects => #err - NoProjects', async function (t) {
	let { ok: projects, err: error } = await project_main_actor.default.get_all_projects([]);

	t.equal(projects.length, 0);
	t.deepEqual(error, undefined);
});

test('ProjectMain[mishicat].delete_projects(): should delete all', async function (t) {
	let { ok: projects_ids } = await project_main_actor.mishicat.get_project_ids();
	let { ok: deleted_projects } = await project_main_actor.mishicat.delete_projects(projects_ids);

	t.equal(deleted_projects, 'Deleted Projects');
});

test('ProjectMain[mishicat].create_project():  => #ok - project', async function (t) {
	const { ok: project_ref } = await project_main_actor.mishicat.create_project('Project One', []);

	t.equal(project_ref.id.length > 3, true);
	t.equal(project_ref.canister_id.length > 3, true);
});

test('ProjectMain[mishicat].get_all_projects(): should have both projects => #ok - projects', async function (t) {
	let { ok: projects } = await project_main_actor.mishicat.get_all_projects([]);
	let first_project = projects[0];

	project_info = first_project;

	t.equal(projects.length > 0, true);
	t.equal(first_project.username, 'mishicat');
	t.equal(first_project.name, 'Project One');
});

test('ProjectMain[motoko].update_project_details(): with wrong identity => #err - ', async function (t) {
	let { ok: projects } = await project_main_actor.mishicat.get_all_projects([]);

	let first_project = projects[0];
	let project_ref = { id: first_project.id, canister_id: first_project.canister_id };

	let { ok: updated_project, err: err_update_project } =
		await project_main_actor.motoko.update_project_details(
			{ name: ['Project One Updated'] },
			project_ref
		);

	t.equal(updated_project, undefined);
	t.deepEqual(err_update_project, { ProjectIdsDoNotMatch: true });

	let { ok: updated_projects } = await project_main_actor.mishicat.get_all_projects([]);

	t.equal(updated_projects[0].name, 'Project One');
});

test('ProjectMain[mishicat].update_project_details(): should update project name => #ok - project name updated', async function (t) {
	let { ok: projects } = await project_main_actor.mishicat.get_all_projects([]);

	let first_project = projects[0];
	let project_ref = { id: first_project.id, canister_id: first_project.canister_id };

	let { ok: updated_project } = await project_main_actor.mishicat.update_project_details(
		{ name: ['Project One Updated'] },
		project_ref
	);
	let { ok: updated_projects } = await project_main_actor.mishicat.get_all_projects([]);

	t.deepEqual(updated_project, 'Updated Project Details');
	t.equal(updated_projects[0].name, 'Project One Updated');
});

test('ProjectMain[mishicat].create_project():  => #ok - project', async function (t) {
	const { ok: project_ref } = await project_main_actor.mishicat.create_project('Project Two', []);

	t.equal(project_ref.id.length > 3, true);
	t.equal(project_ref.canister_id.length > 3, true);
});

test('ProjectMain[mishicat].get_all_projects(): => #ok - two projects', async function (t) {
	let { ok: projects } = await project_main_actor.mishicat.get_all_projects([]);
	let { ok: project_ids } = await project_main_actor.mishicat.get_project_ids();

	t.equal(projects.length, 2);
	t.equal(project_ids.length, 2);
});

test('ProjectMain[mishicat].delete_projects(): should delete all', async function (t) {
	let { ok: projects_ids } = await project_main_actor.mishicat.get_project_ids();
	let { ok: deleted_projects } = await project_main_actor.mishicat.delete_projects(projects_ids);

	t.equal(deleted_projects, 'Deleted Projects');

	let { ok: projects, err: err_projects } = await project_main_actor.mishicat.get_all_projects([]);
	let { ok: project_ids, err: err_project_ids } =
		await project_main_actor.mishicat.get_project_ids();

	t.equal(projects.length, 0);
	t.deepEqual(err_projects, undefined);

	t.equal(project_ids.length, 0);
	t.equal(err_project_ids, undefined);
});

// PROJECT

test('Setup Actors', async function () {
	console.log('=========== Project ===========');

	project_actor.mishicat = await get_actor(
		project_info.canister_id,
		test_project_interface,
		mishicat_identity
	);
});

test('Project[mishicat].create_project(): with wrong caller => #err - NotAuthorized', async function (t) {
	const response = await project_actor.mishicat.create_project(
		'Test',
		[],
		mishicat_identity.getPrincipal()
	);

	t.deepEqual(response.err, { NotAuthorized: null });
});

test('Project[mishicat].delete_projects(): with wrong caller => #err - NotAuthorized', async function (t) {
	const response = await project_actor.mishicat.delete_projects([project_info.id]);

	t.deepEqual(response.err, { NotAuthorized: null });
});

test('Project[mishicat].delete_snaps_from_project(): with wrong caller => #err - NotAuthorized', async function (t) {
	const response = await project_actor.mishicat.delete_snaps_from_project(
		[{ id: project_info.id, canister_id: project_info.canister_id }],
		'yyy',
		mishicat_identity.getPrincipal()
	);

	t.deepEqual(response.err, { NotAuthorized: null });
});
