const test = require('tape');
const fake = require('fake-words');

const { Ed25519KeyIdentity } = require('@dfinity/identity');

// Actor Interface
const {
	assets_img_staging_interface,
	project_main_interface,
	snap_main_interface,
	test_project_interface,
	username_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	assets_img_staging_canister_id,
	project_main_canister_id,
	snap_main_canister_id,
	test_project_canister_id,
	username_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();
const { default_identity } = require('../test-utils/identities/identity.cjs');

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_images } = require('../test-utils/utils.cjs');

let images = generate_images();

let assets_img_staging_actors = {};
let snap_main_actor = {};
let project_main_actor = {};
let project_actor = {};
let username_actors = {};

let img_asset_ids = [];

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

	username_actors.mishicat = await get_actor(
		username_canister_id,
		username_interface,
		mishicat_identity
	);

	snap_main_actor.mishicat = await get_actor(
		snap_main_canister_id,
		snap_main_interface,
		mishicat_identity
	);

	project_main_actor.mishicat = await get_actor(
		project_main_canister_id,
		project_main_interface,
		mishicat_identity
	);

	project_main_actor.defualt = await get_actor(
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

test('ProjectMain[mishicat].initialize_canisters()', async function (t) {
	let project_canister_id = await project_main_actor.mishicat.initialize_canisters([
		test_project_canister_id
	]);

	t.equal(project_canister_id, test_project_canister_id);
});

// NOT AUTHORIZED
test('Project[mishicat].create_project(): with wrong caller => #err - NotAuthorized', async function (t) {
	const response = await project_actor.mishicat.create_project(
		'Test',
		[],
		mishicat_identity.getPrincipal()
	);

	t.deepEqual(response.err, { NotAuthorized: null });
});

test('Project[mishicat].delete_projects(): with wrong caller => #err - NotAuthorized', async function (t) {
	const response = await project_actor.mishicat.delete_projects(['xxx']);

	t.deepEqual(response.err, { NotAuthorized: null });
});

test('Project[mishicat].delete_snaps_from_project(): with wrong caller => #err - NotAuthorized', async function (t) {
	const response = await project_actor.mishicat.delete_snaps_from_project(
		[{ id: 'xxx', canister_id: 'xxx' }],
		'yyy',
		mishicat_identity.getPrincipal()
	);

	t.deepEqual(response.err, { NotAuthorized: null });
});

// CREATE SNAP
test('Username[mishicat].create_username(): should create username => #ok - username', async function (t) {
	const username = fake.word();

	const response = await username_actors.mishicat.create_username(username.toLowerCase());

	t.equal(response.ok.username, username.toLowerCase());
});

test('SnapMain[mishicat].create_user_snap_storage(): should create initial storage for snaps => #ok - true', async function (t) {
	const response = await snap_main_actor.mishicat.create_user_snap_storage();

	t.equal(response, true);
});

test('ImageAssetStaging[mishicat].create_asset(): should create images => #ok - img_asset_ids', async function (t) {
	let promises = [];

	images.forEach(async function (image) {
		const args = {
			data: image,
			file_format: 'png'
		};

		promises.push(assets_img_staging_actors.mishicat.create_asset(args));
	});

	try {
		img_asset_ids = await Promise.all(promises);
		t.equal(img_asset_ids.length, images.length);
	} catch (error) {
		console.log('error: ', error);
	}
});

test('SnapMain[mishicat].create_snap(): should create snap without file asset => #ok - snap', async function (t) {
	let create_args = {
		title: 'Snap One',
		image_cover_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	let response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response, { ok: 'Created Snap' });
});

test('ImageAssetStaging[mishicat].create_asset(): should create images => #ok - img_asset_ids', async function (t) {
	let promises = [];

	images.forEach(async function (image) {
		const args = {
			data: image,
			file_format: 'png'
		};

		promises.push(assets_img_staging_actors.mishicat.create_asset(args));
	});

	try {
		img_asset_ids = await Promise.all(promises);
		t.equal(img_asset_ids.length, images.length);
	} catch (error) {
		console.log('error: ', error);
	}
});

test('SnapMain[mishicat].create_snap(): should create snap without file asset => #ok - snap', async function (t) {
	let create_args = {
		title: 'Snap Two',
		image_cover_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	let response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response, { ok: 'Created Snap' });
});

test('ImageAssetStaging[mishicat].create_asset(): should create images => #ok - img_asset_ids', async function (t) {
	let promises = [];

	images.forEach(async function (image) {
		const args = {
			data: image,
			file_format: 'png'
		};

		promises.push(assets_img_staging_actors.mishicat.create_asset(args));
	});

	try {
		img_asset_ids = await Promise.all(promises);
		t.equal(img_asset_ids.length, images.length);
	} catch (error) {
		console.log('error: ', error);
	}
});

test('SnapMain[mishicat].create_snap(): should create snap without file asset => #ok - snap', async function (t) {
	let create_args = {
		title: 'Snap Three',
		image_cover_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	let response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response, { ok: 'Created Snap' });
});

// CREATE PROJECT
test('ProjectMain[mishicat].create_user_project_storage(): should create initial storage for projects => #ok - true', async function (t) {
	const response = await project_main_actor.mishicat.create_user_project_storage();

	t.deepEqual(response, true);
});

test('ProjectMain[mishicat].create_project(): with snap => #ok - project', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const snap = all_snaps[0];

	const snaps = [{ id: snap.id, canister_id: snap.canister_id }];
	const response = await project_main_actor.mishicat.create_project('Project One', [snaps]);

	t.deepEqual(response.ok, 'Created Project');
});

test('ProjectMain[mishicat].create_project(): with no snaps => #ok - project', async function (t) {
	const snaps = [];
	const response = await project_main_actor.mishicat.create_project('Project Two', snaps);

	t.deepEqual(response.ok, 'Created Project');
});

test('ProjectMain[mishicat].get_projects(): should have both projects', async function (t) {
	let { ok: projects } = await project_main_actor.mishicat.get_projects();

	let first_project = projects[0];
	let second_project = projects[1];

	t.deepEqual(first_project.name, 'Project One');
	t.deepEqual(second_project.name, 'Project Two');
	t.equal(projects.length, 2);
	t.equal(first_project.snaps.length, 1);
	t.equal(second_project.snaps.length, 0);
});

test('SnapMain[mishicat].get_all_snaps(): should have project as part of snap', async function (t) {
	const { ok: snaps } = await snap_main_actor.mishicat.get_all_snaps();

	const project = snaps[0].project[0];

	t.equal(project.name, 'Project One');
	t.equal(project.snaps.length, 1);
	t.equal(project.id.length > 0, true);
});

test('ProjectMain[mishicat].delete_snaps_from_project(): should delete snaps from project', async function (t) {
	const { ok: snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const project = snaps[0].project[0];
	const snap = snaps[0];

	const snaps_delete = [
		{
			id: snap.id,
			canister_id: snap.canister_id
		}
	];

	const project_ref = {
		id: project.id,
		canister_id: project.canister_id
	};

	let response = await project_main_actor.mishicat.delete_snaps_from_project(
		snaps_delete,
		project_ref
	);
	let { ok: projects } = await project_main_actor.mishicat.get_projects();
	const { ok: snaps_after_delete } = await snap_main_actor.mishicat.get_all_snaps();

	t.equal(projects[0].snaps.length, 0);
	t.equal(snaps_after_delete[0].project.length, 0);
	t.equal(response.ok, 'Deleted Snaps From Project');
});

test('ProjectMain[mishicat].add_snaps_to_project(): should move all snaps to project one', async function (t) {
	const { ok: snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const { ok: projects } = await project_main_actor.mishicat.get_projects();

	const snap_refs = snaps.reduce(function (acc, snap) {
		acc.push({
			id: snap.id,
			canister_id: snap.canister_id
		});

		return acc;
	}, []);

	const project_ref = {
		id: projects[0].id,
		canister_id: projects[0].canister_id
	};

	let response = await project_main_actor.mishicat.add_snaps_to_project(snap_refs, project_ref);

	t.equal(response.ok, 'Added Snaps To Project');

	let { ok: all_projects } = await project_main_actor.mishicat.get_projects();
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();

	t.equal(all_projects[0].snaps.length, 3);
	t.equal(all_snaps[0].project[0].id, all_projects[0].id);
	t.equal(all_snaps[0].project[0].name, all_projects[0].name);
});

test('ProjectMain[mishicat].delete_snaps_from_project(): should all delete snaps from project one', async function (t) {
	const { ok: snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const { ok: projects_before } = await project_main_actor.mishicat.get_projects();

	const snap_refs = snaps.reduce(function (acc, snap) {
		acc.push({
			id: snap.id,
			canister_id: snap.canister_id
		});

		return acc;
	}, []);

	const project_ref = {
		id: projects_before[0].id,
		canister_id: projects_before[0].canister_id
	};

	let response = await project_main_actor.mishicat.delete_snaps_from_project(
		snap_refs,
		project_ref
	);

	t.equal(response.ok, 'Deleted Snaps From Project');

	let { ok: projects_after } = await project_main_actor.mishicat.get_projects();
	const { ok: snaps_after } = await snap_main_actor.mishicat.get_all_snaps();

	t.equal(projects_after[0].snaps.length, 0);
	t.equal(snaps_after[0].project.length, 0);
});

test('ProjectMain[mishicat].add_snaps_to_project(): should move all snaps to project two', async function (t) {
	const { ok: snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const { ok: projects } = await project_main_actor.mishicat.get_projects();

	const snap_refs = snaps.reduce(function (acc, snap) {
		acc.push({
			id: snap.id,
			canister_id: snap.canister_id
		});

		return acc;
	}, []);

	const project_ref = {
		id: projects[1].id,
		canister_id: projects[1].canister_id
	};

	let response = await project_main_actor.mishicat.add_snaps_to_project(snap_refs, project_ref);

	t.equal(response.ok, 'Added Snaps To Project');

	let { ok: all_projects } = await project_main_actor.mishicat.get_projects();
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();

	t.equal(all_projects[1].snaps.length, 3);
	t.equal(all_snaps[0].project[0].id, all_projects[1].id);
	t.equal(all_snaps[0].project[0].name, all_projects[1].name);
});

test('ProjectMain[mishicat].delete_projects(): should create and delete project', async function (t) {
	const snaps = [];
	await project_main_actor.mishicat.create_project('Deleted Project', snaps);
	let { ok: projects } = await project_main_actor.mishicat.get_projects();
	let project = projects[2];
	let delete_response = await project_main_actor.mishicat.delete_projects([project.id]);

	t.equal(delete_response.ok, 'Deleted Projects');
});

test('ProjectMain[mishicat].get_projects(): ', async function (t) {
	let { ok: projects } = await project_main_actor.mishicat.get_projects();
	let get_ids_response = await project_main_actor.mishicat.get_project_ids();

	t.equal(projects.length, 2);
	t.equal(get_ids_response.ok.length, 2);
});
