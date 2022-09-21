const test = require('tape');
const fake = require('fake-words');

const { Ed25519KeyIdentity } = require('@dfinity/identity');

// Actor Interface
const {
	assets_img_staging_interface,
	project_main_interface,
	snap_main_interface,
	username_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	assets_img_staging_canister_id,
	project_main_canister_id,
	snap_main_canister_id,
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
let username_actors = {};

let project_with_snaps = null;
let project_no_snaps = null;
let img_asset_ids = [];
let created_snap = {};

test('Setup Actors', async function (t) {
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
});

test('ProjectMain[mishicat].initialize_canisters()', async function (t) {
	let response = await project_main_actor.mishicat.initialize_canisters([]);
});

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
	} catch (error) {
		console.log('error: ', error);
	}
});

test('SnapMain[mishicat].create_snap(): should create snap without file asset => #ok - snap', async function (t) {
	let create_args = {
		title: 'Mobile Example',
		image_cover_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	let { ok } = await snap_main_actor.mishicat.create_snap(create_args);
	created_snap = ok;

	t.equal(ok.title, create_args.title);
	t.equal(ok.image_cover_location, create_args.image_cover_location);
});

test('ProjectMain[mishicat].create_user_project_storage(): should create initial storage for projects => #ok - true', async function (t) {
	const response = await project_main_actor.mishicat.create_user_project_storage();

	t.equal(response, true);
});

test('ProjectMain[mishicat].create_project(): with snap => #ok - project', async function (t) {
	const snaps = [{ id: created_snap.id, canister_id: created_snap.canister_id }];
	const { ok } = await project_main_actor.mishicat.create_project('Mishicat NFT', [snaps]);
	project_with_snaps = ok;

	t.equal(ok.name, 'Mishicat NFT');
	t.equal(ok.snaps.length, 1);
});

test('ProjectMain[mishicat].create_project(): with no snaps => #ok - project', async function (t) {
	const snaps = [];
	project_no_snaps = await project_main_actor.mishicat.create_project('Mishicat NFT', snaps);

	t.equal(project_no_snaps.ok.name, 'Mishicat NFT');
	t.equal(project_no_snaps.ok.snaps.length, 0);
});

test('ProjectMain[mishicat].get_projects(): ', async function (t) {
	let get_response = await project_main_actor.mishicat.get_projects();
	let get_ids_response = await project_main_actor.mishicat.get_project_ids();

	t.equal(get_response.ok.length, 2);
	t.equal(get_ids_response.ok.length, 2);
});

test('SnapMain.get_all_snaps()', async function (t) {
	const response = await snap_main_actor.mishicat.get_all_snaps();

	console.log('response: ', response.ok);
	console.log('response.ok[0].project: ', response.ok[0].project);
});

test('ProjectMain[mishicat].delete_snaps_from_project(): ', async function (t) {
	const snap = project_with_snaps.snaps[0];
	const snaps = [
		{
			id: snap.id,
			canister_id: snap.canister_id
		}
	];

	const project_ref = {
		id: project_with_snaps.id,
		canister_id: project_with_snaps.canister_id
	};

	let response = await project_main_actor.mishicat.delete_snaps_from_project(snaps, project_ref);

	t.equal(response.ok, 'Deleted Snaps From Project');
});

test('ProjectMain[mishicat].delete_projects(): ', async function (t) {
	const snaps = [];
	let create_response = await project_main_actor.mishicat.create_project('Deleted Project', snaps);
	let delete_response = await project_main_actor.mishicat.delete_projects([create_response.ok.id]);
});

test('ProjectMain[mishicat].get_projects(): ', async function (t) {
	let get_response = await project_main_actor.mishicat.get_projects();
	let get_ids_response = await project_main_actor.mishicat.get_project_ids();

	console.log('get_response', get_response.ok);
	console.log('get_ids_response', get_ids_response.ok);
});
