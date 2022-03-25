// const test = require('tape');
// const fetch = require('node-fetch');
// const { getActor } = require('./actor.cjs');
// const canisterIds = require('../.dfx/local/canister_ids.json');
// const {
// 	idlFactory
// } = require('../.dfx/local/canisters/profile_manager/profile_manager.did.test.cjs');
// const { Ed25519KeyIdentity } = require('@dfinity/identity');
// const fs = require('fs');
// const fake = require('fake-words');

// global.fetch = fetch;

// let Mishi = Ed25519KeyIdentity.generate();
// let Motoko = Ed25519KeyIdentity.generate();
// const canisterId = canisterIds.profile_manager.local;

// let profileManager = null;
// const username = fake.word();

// test('Profile Manager: version()', async function (t) {
// 	profileManager = await getActor(canisterId, idlFactory, Mishi);

// 	const response = await profileManager.version();

// 	console.log("version: ", response);
// 	t.equal(typeof response, 'string');
// });

// test('Profile Manager: create_profile with invalid username returns UsernameInvalid', async function (t) {
// 	const response = await profileManager.create_profile(username);

// 	t.deepEqual(response.err, { UsernameInvalid: null });
// });

// test('Profile Manager: create_profile with taken username returns UsernameTaken', async function (t) {
// 	const response = await profileManager.create_profile('cyberowl');

// 	t.deepEqual(response.err, { UsernameTaken: null });
// });

// test('Profile Manager: create_profile() with valid username returns ProfileCreated', async function (t) {
// 	const response = await profileManager.create_profile(username.toLowerCase());

// 	t.deepEqual(response.ok, { ProfileCreated: null });
// });

// test('Profile Manager: get_profile()', async function (t) {
// 	setTimeout(function () {}, 8000);

// 	const response = await profileManager.get_profile();

// 	t.equal(response.ok.username, username.toLowerCase());
// });

// test('Profile Manager: set_avatar()', async function (t) {
// 	try {
// 		const imageAsBuffer = fs.readFileSync('tests/images/motoko.png');

// 		// covert to unit 8 array
// 		const imageAsUnit8ArrayBuffer = new Uint8Array(imageAsBuffer);
// 		const avatar = {
// 			content: [...imageAsUnit8ArrayBuffer]
// 		};

// 		const response = await profileManager.set_avatar(avatar);

// 		t.deepEqual(response.ok, { AvatarCreated: null });
// 	} catch (err) {
// 		console.error(err);
// 	}
// });

// test('Profile Manager: get_profile()', async function (t) {
// 	setTimeout(function () {}, 8000);

// 	const response = await profileManager.get_profile();

// 	t.ok(response.ok.avatar);
// });

// test('Profile Manager: get_profile() with invalid userId ', async function (t) {
// 	setTimeout(function () {}, 8000);

// 	profileManager = await getActor(canisterId, idlFactory, Motoko);

// 	const response = await profileManager.get_profile();

// 	t.deepEqual(response.err, { CanisterIdNotFound: null });
// });
