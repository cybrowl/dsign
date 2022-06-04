const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const { exec } = require('child_process');

const { getActor } = require('../tests/actor.cjs');
const { generateImages } = require('../tests/utils.cjs');

const canisterIds = require('../.dfx/local/canister_ids.json');

const { idlFactory: idlFactorySnapMain } = require('../.dfx/local/canisters/snap_main/snap_main.did.test.cjs');
const { idlFactory: idlFactorySnap } = require('../.dfx/local/canisters/snap/snap.did.test.cjs');
const { idlFactory: idlFactorySnapImages } = require('../.dfx/local/canisters/snap_images/snap_images.did.test.cjs');

global.fetch = fetch;

const { defaultIdentity } = require("../tests/identities/identity.cjs");
let mishiIdentity = Ed25519KeyIdentity.generate();

const snap_main_canister_id = canisterIds.snap_main.local;
const snap_canister_id = canisterIds.snap.local;
const snap_images_canister_id = canisterIds.snap_images.local;

let mishiSnapsMainActor = null;
let defaultSnapsMainActor = null;

let defaultSnapActor = null;
let defaultSnapsImagesActor = null;

test('Snaps Main: assign actors()', async function (t) {
	mishiSnapsMainActor = await getActor(snap_main_canister_id, idlFactorySnapMain, mishiIdentity);
	defaultSnapsMainActor = await getActor(snap_main_canister_id, idlFactorySnapMain, defaultIdentity);

	defaultSnapActor = await getActor(snap_canister_id, idlFactorySnap, defaultIdentity);
	defaultSnapsImagesActor = await getActor(snap_images_canister_id, idlFactorySnapImages, defaultIdentity);

	const response = await mishiSnapsMainActor.version();
	t.equal(typeof response, 'string');

	console.log("=========== Snaps Main ===========");
	console.log('version: ', response);
});

test('Snaps Main: initialize_canisters()', async function (t) {
	const snapCanisterId = await defaultSnapActor.get_canister_id();
	const snapImagesCanisterId = await defaultSnapsImagesActor.get_canister_id();

	await defaultSnapsMainActor.initialize_canisters([snapCanisterId], [snapImagesCanisterId]);
});

test('Snaps Main: inistialize_user()', async function (t) {
	const response = await defaultSnapsMainActor.inistialize_user();

	console.log('inistialize_user: ', response);
});

test('Snaps Main: create_snap()', async function (t) {
	let createArgs = {
		title: 'mobile',
		is_public: true,
		cover_image_location: 1,
		images: generateImages()
	};

	const response = await defaultSnapsMainActor.create_snap(createArgs);

	console.log('create_snap: ', response);
});

test('Snaps Main: create_snap()', async function (t) {
	let createArgs = {
		title: 'desktop',
		is_public: true,
		cover_image_location: 0,
		images: generateImages()
	};

	const response = await defaultSnapsMainActor.create_snap(createArgs);

	console.log('create_snap: ', response);
});

test('Snaps Main: get_all_snaps()', async function (t) {
	const response = await defaultSnapsMainActor.get_all_snaps();

	console.log('get_all_snaps: ', response);
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
