const test = require('tape');
const fetch = require('node-fetch');
const fake = require('fake-words');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const {
	idlFactory: username_interface
} = require('../.dfx/local/canisters/username/username.did.test.cjs');

// Canister Ids
const canister_ids = require('../.dfx/local/canister_ids.json');
const username_canister_id = canister_ids.username.local;

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let mishicat_username_actor = null;

test('Username.version()', async function (t) {
	mishicat_username_actor = await get_actor(
		username_canister_id,
		username_interface,
		mishicat_identity
	);

	const response = await mishicat_username_actor.version();

	console.log('=========== Snaps Images ===========');
	console.log('version: ', response);
});


test('Username.mishicat_username_actor()', async function (t) {
	const response = await mishicat_username_actor.get_username();

	t.deepEqual(response.err, { UserNotFound: null });
});

test('Username.save_username():: with invalid username => #err - UsernameInvalid', async function (t) {
	const username = fake.word();
	const response = await mishicat_username_actor.save_username(username);

	t.deepEqual(response.err, { UsernameInvalid: null });
});

test('Username.save_username():: with taken username => #err - UsernameTaken', async function (t) {
	const username = 'mishicat';
	await mishicat_username_actor.save_username(username);
	const response = await mishicat_username_actor.save_username(username);

	t.deepEqual(response.err, { UsernameTaken: null });
});

test('Username.save_username():: with valid username => #ok - username', async function (t) {
	const username = fake.word();
	const response = await mishicat_username_actor.save_username(username.toLowerCase());

	t.equal(response.ok, username.toLowerCase());
});


