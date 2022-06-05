const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const { exec } = require('child_process');

global.fetch = fetch;

// Actor Interface
const { idlFactory: snap_main_interface } = require('../.dfx/local/canisters/snap_main/snap_main.did.test.cjs');
const { idlFactory: snap_interface } = require('../.dfx/local/canisters/snap/snap.did.test.cjs');
const { idlFactory: snap_images_interface } = require('../.dfx/local/canisters/snap_images/snap_images.did.test.cjs');

// Canister Ids
const canister_ids = require('../.dfx/local/canister_ids.json');
const snap_main_canister_id = canister_ids.snap_main.local;
const snap_canister_id = canister_ids.snap.local;
const snap_images_canister_id = canister_ids.snap_images.local;

// Identities
const { default_identity } = require("../test-utils/identities/identity.cjs");
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_images } = require('../test-utils/utils.cjs');

let mishicat_snap_main_actor = null;
let default_snap_main_actor = null;

let default_snap_actor = null;
let default_snap_images_actor = null;

test('Snaps Main: assign actors()', async function (t) {
	mishicat_snap_main_actor = await get_actor(snap_main_canister_id, snap_main_interface, mishicat_identity);
	default_snap_main_actor = await get_actor(snap_main_canister_id, snap_main_interface, default_identity);

	default_snap_actor = await get_actor(snap_canister_id, snap_interface, default_identity);
	default_snap_images_actor = await get_actor(snap_images_canister_id, snap_images_interface, default_identity);

	const response = await mishicat_snap_main_actor.version();
	t.equal(typeof response, 'string');

	console.log("=========== Snaps Main ===========");
	console.log('version: ', response);
});

test('Snaps Main: initialize_canisters()', async function (t) {
	const snap_canister_id = await default_snap_actor.get_canister_id();
	const snap_images_canister_id = await default_snap_images_actor.get_canister_id();

	await default_snap_main_actor.initialize_canisters([snap_canister_id], [snap_images_canister_id]);
});

test('Snaps Main: inistialize_user()', async function (t) {
	const response = await default_snap_main_actor.inistialize_user();

	console.log('inistialize_user: ', response);
});

test('Snaps Main: create_snap()', async function (t) {
	let create_args = {
		title: 'mobile',
		is_public: true,
		cover_image_location: 1,
		images: generate_images()
	};

	const response = await default_snap_main_actor.create_snap(create_args);

	console.log('create_snap: ', response);
});

test('Snaps Main: create_snap()', async function (t) {
	let create_args = {
		title: 'desktop',
		is_public: true,
		cover_image_location: 0,
		images: generate_images()
	};

	const response = await default_snap_main_actor.create_snap(create_args);

	console.log('create_snap: ', response);
});

test('Snaps Main: get_all_snaps()', async function (t) {
	const response = await default_snap_main_actor.get_all_snaps();

	console.info('get_all_snaps: ', response.ok);
});

test('Logs', async function (t) {
	exec('npm run logs', (error, stdout, stderr) => {
		if (error) {
			console.log(`error: ${error.message}`);
			return;
		}
		if (stderr) {
			console.info(`stderr: ${stderr}`);
			return;
		}
		console.info(`stdout: ${stdout}`);
	});
});
