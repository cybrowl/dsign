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

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const snaps_canister_id = canisterIds.snaps.local;
const snap_canister_id = canisterIds.snap.local;
const snap_images_canister_id = canisterIds.snap_images.local;

let SnapsMainActor = null;
let SnapMainActor = null;
let SnapImagesMainActor = null;

test('Snaps Main: version()', async function (t) {
	SnapsMainActor = await getActor(snaps_canister_id, idlFactory, Mishi);
	SnapMainActor = await getActor(snap_canister_id, idlFactorySnap, Mishi);
	SnapImagesMainActor = await getActor(snap_images_canister_id, idlFactorySnapImages, Mishi);

	const response = await SnapsMainActor.version();

	console.log('version: ', response);
	t.equal(typeof response, 'string');
});

test('Snaps Main: initialize_canisters()', async function (t) {
	const snapCanisterId = await SnapMainActor.get_canister_id();
	const snapImagesCanisterId = await SnapImagesMainActor.get_canister_id();
	console.log("snapCanisterId: ", snapCanisterId);
	console.log("snapImagesCanisterId: ", snapImagesCanisterId);

	const response = await SnapsMainActor.initialize_canisters([snapCanisterId], [snapImagesCanisterId]);

	console.log('response: ', response);
});

test('Snaps Main: create_snap()', async function (t) {
	let createArgs = {
		title: 'mobile',
		isPublic: true,
		coverImageLocation: 1,
		images: generateImages()
	};

	const response = await SnapsMainActor.create_snap(createArgs);

	console.log('create_snap: ', response);
});

test('Snaps Main: create_snap()', async function (t) {
	let createArgs = {
		title: 'desktop',
		isPublic: true,
		coverImageLocation: 0,
		images: generateImages()
	};

	const response = await SnapsMainActor.create_snap(createArgs);

	console.log('create_snap: ', response);
});

// test('Snaps Main: get_snap()', async function (t) {
// 	const response = await SnapsMainActor.get_snap();

// 	console.log('get_snap: ', response);
// });

// test('Logs', async function (t) {
// 	exec('npm run logs', (error, stdout, stderr) => {
// 		if (error) {
// 			console.log(`error: ${error.message}`);
// 			return;
// 		}
// 		if (stderr) {
// 			console.log(`stderr: ${stderr}`);
// 			return;
// 		}
// 		console.log(`stdout: ${stdout}`);
// 	});
// });
