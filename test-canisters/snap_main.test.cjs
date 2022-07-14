const test = require('tape');
const fake = require('fake-words');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const { snap_main_interface, username_interface } = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	snap_main_canister_id,
	username_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { default_identity } = require('../test-utils/identities/identity.cjs');
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_images } = require('../test-utils/utils.cjs');

let images = generate_images();

let snap_main_actor = {};
let username_actors = {};

let created_snap = {};

test('SnapMain.assign actors()', async function (t) {
	console.log('snap_main_canister_id: ', snap_main_canister_id);

	snap_main_actor.mishicat = await get_actor(
		snap_main_canister_id,
		snap_main_interface,
		mishicat_identity
	);
	snap_main_actor.default = await get_actor(
		snap_main_canister_id,
		snap_main_interface,
		default_identity
	);

	username_actors.mishicat = await get_actor(
		username_canister_id,
		username_interface,
		mishicat_identity
	);
	username_actors.default = await get_actor(
		username_canister_id,
		username_interface,
		default_identity
	);

	const response = await snap_main_actor.mishicat.version();
	t.equal(typeof response, 'string');

	console.log('=========== Snap Main ===========');
	console.log('version: ', response);
});

test('SnapMain.initialize_canisters()', async function (t) {
	// const snap_canister_id = await default_snap_actor.get_canister_id();
	// const snap_images_canister_id = await default_snap_images_actor.get_canister_id();

	await snap_main_actor.mishicat.initialize_canisters([], []);
});

test('Username.create_username()::[username_actors.mishicat]: create first with valid username => #ok - username', async function (t) {
	const username = fake.word();

	const response = await username_actors.mishicat.create_username(username.toLowerCase());

	t.equal(response.ok.username, username.toLowerCase());
});

test('SnapMain.create_user_snap_storage()::[snap_main_actor.mishicat]: create initial storage for snaps => #ok - true', async function (t) {
	const response = await snap_main_actor.mishicat.create_user_snap_storage();

	t.equal(response, true);
});

test('SnapMain.create_snap()::[snap_main_actor.mishicat] => #err - too many images', async function (t) {
	let create_args = {
		title: 'mobile',
		is_public: true,
		cover_image_location: 1,
		images: [{ data: images[0] }, { data: images[1] }]
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.err, { OneImageMax: null });
});

test('SnapMain.create_snap()', async function (t) {
	let create_args = {
		title: 'mobile',
		is_public: true,
		cover_image_location: 1,
		images: [{ data: images[0] }]
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);
	created_snap = response.ok;

	t.deepEqual(response.ok.image_urls.length, 1);
});

test('SnapMain.finalize_snap_creation()', async function (t) {
	let snap_creation_promises = [];

	for (const image of images) {
		let snap_temp = {
			canister_id: created_snap.canister_id,
			snap_id: created_snap.id,
			images: [{ data: image }]
		};

		snap_creation_promises.push(snap_main_actor.mishicat.finalize_snap_creation(snap_temp));
	}
	console.info("snap_creation_promises:", snap_creation_promises[0])

	const responses = await Promise.all(snap_creation_promises);
});

test('SnapMain.get_all_snaps()', async function (t) {
	const response = await snap_main_actor.mishicat.get_all_snaps();

	console.info('get_all_snaps: ', response.ok);
});
