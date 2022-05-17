const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const { callImageCanister } = require("./utils.cjs");
const fs = require('fs');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const avatarCanisterId = canisterIds.profile_avatar.local;
let host = 'http://127.0.0.1:8000';
let profileAvatar = null;

test('Profile Avatar: version()', async function (t) {
	profileAvatar = await getActor(avatarCanisterId, idlFactory, Mishi);

	const response = await profileAvatar.version();

	console.log('version: ', response);
	t.equal(typeof response, 'string');
});

test('Profile Avatar: set()', async function (t) {
	try {
		const imageAsBuffer = fs.readFileSync('tests/images/mishicat.png');

		// covert to unit 8 array
		const imageAsUnit8ArrayBuffer = new Uint8Array(imageAsBuffer);
		const image = {
			content: [...imageAsUnit8ArrayBuffer]
		};

		const response = await profileAvatar.set(image, 'mishi');

		t.equal(response, true);
	} catch (err) {
		console.error(err);
	}
});

test('Profile Avatar: should find avatar', async function (t) {
	const path = `${host}/avatar/mishi?canisterId=${avatarCanisterId}`;

	console.log("path: ", path);

	let response = await callImageCanister(path);

	t.strictEqual(response.statusCode, 200);
});

test('Profile Avatar: should NOT find avatar', async function (t) {
	const path = `${host}/avatar/mish?canisterId=${avatarCanisterId}`;
	let response = await callImageCanister(path);

	t.strictEqual(response.statusCode, 404);
});

test('Profile Avatar: save over 2MB()', async function (t) {
	try {
		const imageAsBuffer = fs.readFileSync('tests/images/image_2MB.png');

		// covert to unit 8 array
		const imageAsUnit8ArrayBuffer = new Uint8Array(imageAsBuffer);
		const image = {
			content: [...imageAsUnit8ArrayBuffer]
		};

		const response = await profileAvatar.set(image, 'overlimit');

        t.equal(response, false);
	} catch (err) {
		console.error(err);
	}
});

test('Profile Avatar: should NOT find avatar', async function (t) {
	const path = `${host}/avatar/overlimit?canisterId=${avatarCanisterId}`;
	let response = await callImageCanister(path);

	t.strictEqual(response.statusCode, 404);
});
