const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/profile_manager/profile_manager.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const fs = require('fs');
const fake = require('fake-words');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.profile_manager.local;

let profileManager = null;
const username = fake.word();

test('Profile Manager: ping()', async function (t) {
	profileManager = await getActor(canisterId, idlFactory, Mishi);

	const response = await profileManager.ping();

	t.equal(typeof response, 'string');
	t.equal(response, 'meow');
});

test('Profile Manager: create_profile()', async function (t) {
	const response = await profileManager.create_profile(username);

	t.strictEqual(response.ok, 'profile_created');
});

test('Profile Manager: get_profile()', async function (t) {
	setTimeout(function () {}, 8000);

	const response = await profileManager.get_profile();

	t.equal(response.ok.username, username);
});

test('Profile Manager: set_avatar()', async function (t) {
	try {
		const imageAsBuffer = fs.readFileSync('tests/images/motoko.png');

		// covert to unit 8 array
		const imageAsUnit8ArrayBuffer = new Uint8Array(imageAsBuffer);
		const avatar = {
			content: [...imageAsUnit8ArrayBuffer]
		};

		console.log("avatar: ", avatar);

		const response = await profileManager.set_avatar(avatar);

		t.equal(response.ok, 'avatar_created');
	} catch (err) {
		console.error(err);
	}
});

test('Profile Manager: get_profile()', async function (t) {
	setTimeout(function () {}, 8000);

	const response = await profileManager.get_profile();

	console.log('profile: ', response);

	t.ok(response.ok.avatar);
});
