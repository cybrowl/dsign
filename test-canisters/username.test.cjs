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
let motoko_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let mishicat_username_actor = null;
let motoko_username_actor = null;

test('Username.version()', async function (t) {
	mishicat_username_actor = await get_actor(
		username_canister_id,
		username_interface,
		mishicat_identity
	);

	motoko_username_actor = await get_actor(
		username_canister_id,
		username_interface,
		motoko_identity
	);

	const response = await mishicat_username_actor.version();

	console.log('=========== Snaps Images ===========');
	console.log('version: ', response);
});


test('Username.get_username()::[mishicat_username_actor]: no username created => #err - UserNotFound', async function (t) {
	const response = await mishicat_username_actor.get_username();

	t.deepEqual(response.err, { UserNotFound: null });
});

test('Username.create_username()::[mishicat_username_actor] with invalid username => #err - UsernameInvalid', async function (t) {
	const username = fake.word();
	const response = await mishicat_username_actor.create_username(username);

	t.deepEqual(response.err, { UsernameInvalid: null });
});

test('Username.create_username()::[motoko_username_actor]: with taken username => #err - UsernameTaken', async function (t) {
	const username = 'mishicat';
	await motoko_username_actor.create_username(username);
	const response = await motoko_username_actor.create_username(username);

	t.deepEqual(response.err, { UsernameTaken: null });
});

test('Username.create_username()::[motoko_username_actor]: owner with new username => #err - UsernameTaken', async function (t) {
	const username = fake.word();
	const response = await mishicat_username_actor.create_username(username.toLowerCase());

	t.equal(response.ok, username.toLowerCase());
});

test('Username.create_username()::[mishicat_username_actor]: with new valid username => #err - UserHasUsername', async function (t) {
	const username = fake.word();
	const response = await mishicat_username_actor.create_username(username.toLowerCase());
	
	t.deepEqual(response.err, { UserHasUsername: null });
});