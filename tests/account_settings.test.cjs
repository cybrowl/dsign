const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/account_settings/account_settings.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const fs = require('fs');
const fake = require('fake-words');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
let Motoko = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.account_settings.local;

let accountSettings = null;
const username = fake.word();

test('Account Settings: version()', async function (t) {
	accountSettings = await getActor(canisterId, idlFactory, Mishi);

	const response = await accountSettings.version();

	console.log("version: ", response);
	t.equal(typeof response, 'string');
});

test('Account Settings: create_profile with invalid username returns UsernameInvalid', async function (t) {
	const response = await accountSettings.create_profile(username);

	t.deepEqual(response.err, { UsernameInvalid: null });
});

test('Account Settings: create_profile with taken username returns UsernameTaken', async function (t) {
	const response = await accountSettings.create_profile('cyberowl');

	t.deepEqual(response.err, { UsernameTaken: null });
});

test('Account Settings: create_profile with valid username returns ProfileCreated', async function (t) {
	const response = await accountSettings.create_profile(username.toLowerCase());

	t.deepEqual(response.ok, { ProfileCreated: null });
});

test('Account Settings: get_profile()', async function (t) {
	setTimeout(function () {}, 8000);

	const response = await accountSettings.get_profile();

	t.equal(response.ok.username, username.toLowerCase());
});

test('Account Settings: get_username()', async function (t) {
	setTimeout(function () {}, 8000);

	const userId = await accountSettings.whoami();
	const response = await accountSettings.get_username(userId);

	t.equal(typeof response, 'string');
});

test('Account Settings: set_avatar()', async function (t) {
	try {
		const imageAsBuffer = fs.readFileSync('tests/images/motoko.png');

		// covert to unit 8 array
		const imageAsUnit8ArrayBuffer = new Uint8Array(imageAsBuffer);
		const avatar = {
			content: [...imageAsUnit8ArrayBuffer]
		};

		const response = await accountSettings.set_avatar(avatar);

		t.deepEqual(response.ok, { AvatarCreated: null });
	} catch (err) {
		console.error(err);
	}
});

test('Account Settings: get_profile()', async function (t) {
	setTimeout(function () {}, 8000);

	const response = await accountSettings.get_profile();

	t.ok(response.ok.avatar);
});

test('Account Settings: get_profile() with invalid userId ', async function (t) {
	setTimeout(function () {}, 8000);

	accountSettings = await getActor(canisterId, idlFactory, Motoko);

	const response = await accountSettings.get_profile();

	t.deepEqual(response.err, { CanisterIdNotFound: null });
});
