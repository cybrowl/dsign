const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const {
	idlFactory: snap_images_interface
} = require('../.dfx/local/canisters/snap_images/snap_images.did.test.cjs');

// Canister Ids
const canister_ids = require('../.dfx/local/canister_ids.json');
const snap_images_canister_id = canister_ids.snap_images.local;

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_images } = require('../test-utils/utils.cjs');

let snap_images_actor = null;

test('SnapImages.version()', async function (t) {
	snap_images_actor = await get_actor(
		snap_images_canister_id,
		snap_images_interface,
		mishicat_identity
	);

	const response = await snap_images_actor.version();

	console.log('=========== Snaps Images ===========');
	console.log('version: ', response);
});

test('SnapImages.get_canister_id():: => snap_images_canister_id', async function (t) {
	const snap_images_canister_id = await snap_images_actor.get_canister_id();

	let has_snap_images_canister_id = snap_images_canister_id.length > 1;

	t.equal(has_snap_images_canister_id, true);
});

test('SnapImages.save_images():: for motoko and mishicat images', async function (t) {
	const image_urls = await snap_images_actor.save_images(generate_images());

	console.log("image_urls: ", image_urls);
	t.equal(image_urls.length, 2);
});

test('SnapImages.save_images():: http request returns 200', async function (t) {
	//TODO: test http request to images
});