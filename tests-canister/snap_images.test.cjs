const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

const { getActor } = require('../tests/actor.cjs');
const { callImageCanister, generateImages } = require('../tests/utils.cjs');

const canisterIds = require('../.dfx/local/canister_ids.json');
const { idlFactory } = require('../.dfx/local/canisters/snap_images/snap_images.did.test.cjs');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.snap_images.local;
let host = 'http://127.0.0.1:8000';
let snapImagesActor = null;

test('Snap Images: version()', async function (t) {
	snapImagesActor = await getActor(canisterId, idlFactory, Mishi);

	const response = await snapImagesActor.version();

	console.log('version: ', response);
	t.equal(typeof response, 'string');
});

test('Snap Images: add()', async function (t) {
	// Note: local dev refernces images via
	// http://qoctq-giaaa-aaaaa-aaaea-cai.localhost:8000/snap_image/70KXHF4E2ZFJCPQ5TSBM6F9Y5Z

	const response = await snapImagesActor.save_images(generateImages());
	const canisterID = await snapImagesActor.get_canister_id();

	const path = `${host}/mishicat/snap/image/${response[0]}?canisterId=${canisterID}`;

	console.log('path: ', path);
	let responseGetImage = await callImageCanister(path);

	t.strictEqual(responseGetImage.statusCode, 200);
	console.log('canisterID: ', canisterID);
	console.log('response: ', response);
});
