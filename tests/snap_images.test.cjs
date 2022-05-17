const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/snap_images/snap_images.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const fs = require('fs');
const { callImageCanister } = require("./utils.cjs");

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.snap_images.local;
let host = 'http://127.0.0.1:8000';
let snapImages = null;

test('Snap Images: version()', async function (t) {
	snapImages = await getActor(canisterId, idlFactory, Mishi);

	const response = await snapImages.version();

	console.log("version: ", response);
	t.equal(typeof response, 'string');
});

test('Snap Images: add()', async function (t) {
	const mishicatImageBuffer = fs.readFileSync('tests/images/mishicat.png');
	const motokoImageBuffer = fs.readFileSync('tests/images/motoko.png');

	// covert to unit 8 array
	const mishicatUnit8ArrayBuffer = new Uint8Array(mishicatImageBuffer);
	const motokoUnit8ArrayBuffer = new Uint8Array(motokoImageBuffer);

	const images = [[...mishicatUnit8ArrayBuffer], [...motokoUnit8ArrayBuffer]];

	const response = await snapImages.add(images);
	const canisterID = await snapImages.get_canister_id();

	// https://cljm4-uiaaa-aaaag-aabcq-cai.raw.ic0.app/mishicat/snap/image/192929393939

	const path = `${host}/mishicat/snap/image/${response[0]}?canisterId=${canisterID}`;

	console.log("path: ", path);
	let responseGetImage = await callImageCanister(path);

	t.strictEqual(responseGetImage.statusCode, 200);
	console.log("canisterID: ", canisterID);
	console.log("response: ", response);
});
