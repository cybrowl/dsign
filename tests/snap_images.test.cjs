const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/snap_images/snap_images.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.snap_images.local;

let snapImages = null;

test('Snap Images: version()', async function (t) {
	snapImages = await getActor(canisterId, idlFactory, Mishi);

	const response = await snapImages.version();

	console.log("version: ", response);
	t.equal(typeof response, 'string');
});

test('Snap Images: add()', async function (t) {
	const response = await snapImages.add();

	console.log("response: ", response);
});

test('Snap Images: add()', async function (t) {
	const response = await snapImages.add();

	console.log("response: ", response);
});

test('Snap Images: add()', async function (t) {
	const response = await snapImages.add();

	console.log("response: ", response);
});