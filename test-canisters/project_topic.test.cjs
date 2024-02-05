const test = require('tape');
const { config } = require('dotenv');

config();

// Actor Interface
const {
	project_main_interface,
	assets_img_staging_interface,
	snap_main_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	assets_img_staging_canister_id,
	project_main_canister_id,
	snap_main_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { parseIdentity } = require('../test-utils/identities/identity.cjs');

let default_identity = parseIdentity(process.env.DEFAULT_IDENTITY);

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_flower_images, replacer } = require('../test-utils/utils.cjs');

let assets_img_staging_actors = {};
let project_main_actor = {};
let snap_main_actor = {};
let project_ref_one = {};
let img_asset_ids = [];

test('Initialize Actors for Project, Asset Staging, and Snap Modules', async function (t) {
	console.log('=========== Project Topic ===========');

	project_main_actor.default = await get_actor(
		project_main_canister_id,
		project_main_interface,
		default_identity
	);

	assets_img_staging_actors.default = await get_actor(
		assets_img_staging_canister_id,
		assets_img_staging_interface,
		default_identity
	);

	snap_main_actor.default = await get_actor(
		snap_main_canister_id,
		snap_main_interface,
		default_identity
	);
	t.end();
});

test('Verify ProjectMain Interface Version', async function (t) {
	let version = await project_main_actor.default.version();

	t.assert(version === 3n, 'Correct Version');
	t.end();
});

test('Create Project and Validate Project Reference', async function (t) {
	const { ok: project_ref } = await project_main_actor.default.create_project({
		name: 'Project One',
		description: 'Descripton of Project',
		snaps: []
	});

	project_ref_one = project_ref;

	t.assert(project_ref.id.length > 3, 'Project ID is valid');
	t.assert(project_ref.canister_id.length > 3, 'Project canister ID is valid');
	t.end();
});

test('Create Image Asset and Validate Asset IDs', async function (t) {
	let promises = [];
	let images = generate_flower_images();

	images.forEach((image) => {
		const args = {
			data: image,
			file_format: 'png'
		};

		promises.push(assets_img_staging_actors.default.create_asset(args));
	});

	try {
		img_asset_ids = await Promise.all(promises);
		t.pass('Image assets created successfully');
	} catch (error) {
		console.error('error: ', error);
		t.fail('Image asset creation failed');
	}
	t.end();
});

test('Create Snap with Images and Verify Success', async function (t) {
	let create_args = {
		title: 'Mobile Example',
		project: project_ref_one,
		image_cover_location: 1,
		tags: [],
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	const response = await snap_main_actor.default.create_snap(create_args);

	t.ok(!response.err, 'Snap creation should succeed without errors');
	t.ok(response.ok, 'Snap creation confirmed successful');
	t.end();
});

test('Create Topic Without File and Verify Success', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.default.get_all_snaps();
	const snap = all_snaps[0];

	const topic_info = {
		snap_ref: snap,
		name: 'fix button color',
		note: 'The button color is wrong on this snap',
		file: []
	};

	let { ok: topic, err: error } = await project_main_actor.default.create_topic(
		project_ref_one.id,
		project_ref_one.canister_id,
		topic_info
	);
	t.ok(topic, 'Topic creation should succeed without a file');
	t.end();
});

test('Retrieve All Projects and Validate Structure and Content', async function (t) {
	let { ok: projects } = await project_main_actor.default.get_all_projects([]);

	if (projects && projects.length > 0) {
		const project = projects[0];

		// Validate project structure and content
		t.equal(typeof project.id, 'string', 'Project ID is a string');
		t.equal(project.name, 'Project One', 'Project name matches');
		t.equal(project.description, 'Descripton of Project', 'Project description matches');

		// Validate feedback structure
		t.ok(project.feedback && project.feedback.length > 0, 'Feedback array exists and is not empty');
		const feedback = project.feedback[0];
		t.ok(
			feedback.topics && feedback.topics.length > 0,
			'Topics array within feedback exists and is not empty'
		);

		// Validate topics structure within feedback
		const topic = feedback.topics[0];
		t.equal(typeof topic.id, 'string', 'Topic ID is a string');
		t.equal(topic.name, 'fix button color', 'Topic name matches');
		t.equal(
			topic.messages[0].content,
			'The button color is wrong on this snap',
			'Message content matches'
		);

		// Validate snaps structure
		t.ok(project.snaps && project.snaps.length > 0, 'Snaps array exists and is not empty');
		const snap = project.snaps[0];
		t.equal(typeof snap.id, 'string', 'Snap ID is a string');
		t.equal(snap.title, 'Mobile Example', 'Snap title matches');
	} else {
		t.fail('No projects retrieved');
	}

	t.end();
});

test('Delete All Projects and Validate Deletion', async function (t) {
	let { ok: projects_ids } = await project_main_actor.default.get_project_ids();

	let { ok: deleteResponse } = await project_main_actor.default.delete_projects(projects_ids);

	t.ok(deleteResponse, 'All projects should be deleted successfully');

	let { ok: projectsAfterDeletion, err: errorAfterDeletion } =
		await project_main_actor.default.get_project_ids();

	t.equal(projectsAfterDeletion.length, 0, 'No projects should exist after deletion');

	t.end();
});

test('Delete All Snaps and Validate Deletion', async function (t) {
	let { ok: snap_ids } = await snap_main_actor.default.get_snap_ids();

	if (snap_ids && snap_ids.length > 0) {
		let { ok: deleteResponse } = await snap_main_actor.default.delete_snaps(snap_ids, {
			id: project_ref_one.id,
			canister_id: project_ref_one.canister_id
		});

		t.ok(deleteResponse, 'All snaps should be deleted successfully');

		let { ok: snapsAfterDeletion, err: errorAfterDeletion } =
			await snap_main_actor.default.get_snap_ids();

		t.equal(snapsAfterDeletion.length, 0, 'No snaps should exist after deletion');
	} else {
		t.pass('No snaps available to delete');
	}

	t.end();
});
