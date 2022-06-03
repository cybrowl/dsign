const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const { exec } = require('child_process');

const { getActor } = require('../tests/actor.cjs');
const { generateImages } = require('../tests/utils.cjs');

const canisterIds = require('../.dfx/local/canister_ids.json');
const { idlFactory } = require('../.dfx/local/canisters/snaps/snaps.did.test.cjs');
const { idlFactory: idlFactorySnap } = require('../.dfx/local/canisters/snap/snap.did.test.cjs');
const { idlFactory: idlFactorySnapImages } = require('../.dfx/local/canisters/snap_images/snap_images.did.test.cjs');

const { defaultIdentity, keeperOfCoinIdentity } = require("../tests/identities/identity.cjs");

global.fetch = fetch;

let mishiIdentity = Ed25519KeyIdentity.generate();

const snaps_canister_id = canisterIds.snaps.local;
const snap_canister_id = canisterIds.snap.local;
const snap_images_canister_id = canisterIds.snap_images.local;

let mishiSnapsMainActor = null;
let defaultSnapsMainActor = null;
let SnapMainActor = null;
let SnapImagesMainActor = null;

test('Snaps Main: assign actors()', async function (t) {
	mishiSnapsMainActor = await getActor(snaps_canister_id, idlFactory, mishiIdentity);
	defaultSnapsMainActor = await getActor(snaps_canister_id, idlFactory, defaultIdentity);

	SnapMainActor = await getActor(snap_canister_id, idlFactorySnap, mishiIdentity);
	SnapImagesMainActor = await getActor(snap_images_canister_id, idlFactorySnapImages, mishiIdentity);

	const response = await mishiSnapsMainActor.version();
	t.equal(typeof response, 'string');

	console.log("=========== Snaps Main ===========");
	console.log('version: ', response);
});

test('Snaps Main: initialize_canisters()', async function (t) {
	const snapCanisterId = await SnapMainActor.get_canister_id();
	const snapImagesCanisterId = await SnapImagesMainActor.get_canister_id();
	console.log("snapCanisterId: ", snapCanisterId);
	console.log("snapImagesCanisterId: ", snapImagesCanisterId);

	const response = await defaultSnapsMainActor.initialize_canisters([snapCanisterId], [snapImagesCanisterId]);

	console.log('response: ', response);
});

test('Snaps Main: create_snap()', async function (t) {
	let createArgs = {
		title: 'mobile',
		isPublic: true,
		coverImageLocation: 1,
		images: generateImages()
	};

	const response = await defaultSnapsMainActor.create_snap(createArgs);

	console.log('create_snap: ', response);
});

test('Snaps Main: create_snap()', async function (t) {
	let createArgs = {
		title: 'desktop',
		isPublic: true,
		coverImageLocation: 0,
		images: generateImages()
	};

	const response = await defaultSnapsMainActor.create_snap(createArgs);

	console.log('create_snap: ', response);
});

test('Snaps Main: get_all_snaps()', async function (t) {
	const response = await defaultSnapsMainActor.get_all_snaps();

	console.log("response: ", response.ok[0].images);
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
