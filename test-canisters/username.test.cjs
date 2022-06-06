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
let anonymous_identity = null;

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let username_actors = {};


test('Username.assign actors()', async function (t) {
	username_actors.mishicat = await get_actor(
		username_canister_id,
		username_interface,
		mishicat_identity
	);

	username_actors.motoko = await get_actor(
		username_canister_id,
		username_interface,
		motoko_identity
	);

	username_actors.anonymous = await get_actor(
		username_canister_id,
		username_interface,
		anonymous_identity
	);
	const response = await username_actors.mishicat.version();

	console.log('=========== Username ===========');
	console.log('version: ', response);
});

// get_username
test('Username.get_username()::[username_actors.mishicat]: no username created => #err - UserNotFound', async function (t) {
	const response = await username_actors.mishicat.get_username();

	t.deepEqual(response.err, { UserNotFound: null });
});

test('Username.get_username()::[username_actors.motoko]: no username created => #err - UserNotFound', async function (t) {
	const response = await username_actors.motoko.get_username();

	t.deepEqual(response.err, { UserNotFound: null });
});

// create_username
test('Username.create_username()::[username_actors.anonymous] with anon identity => #err - UserAnonymous', async function (t) {
	const username = fake.word();

	const response = await username_actors.anonymous.create_username(username.toLowerCase());

	t.deepEqual(response.err, { UserAnonymous: null });
});

test('Username.create_username()::[username_actors.mishicat] with invalid username => #err - UsernameInvalid', async function (t) {
	const username = fake.word();

	const response = await username_actors.mishicat.create_username(username);

	t.deepEqual(response.err, { UsernameInvalid: null });
});

test('Username.create_username()::[username_actors.mishicat]: with taken username => #err - UsernameTaken', async function (t) {
	const username = fake.word();

	const createdUsername = await username_actors.mishicat.create_username(username.toLowerCase());
	const response = await username_actors.mishicat.create_username(username.toLowerCase());

	t.equal(createdUsername.ok.username, username.toLowerCase());
	t.deepEqual(response.err, { UsernameTaken: null });
});

test('Username.create_username()::[username_actors.motoko]: create first with valid username => #ok - username', async function (t) {
	const username = fake.word();

	const response = await username_actors.motoko.create_username(username.toLowerCase());

	t.equal(response.ok.username, username.toLowerCase());
});

test('Username.create_username()::[username_actors.motoko]: create second with new valid username => #err - UserHasUsername', async function (t) {
	const username = fake.word();

	const response = await username_actors.motoko.create_username(username.toLowerCase());

	t.deepEqual(response.err, { UserHasUsername: null });
});

// update_username
test('Username.update_username()::[username_actors.anonymous] with anon identity => #err - UserAnonymous', async function (t) {
	const username = fake.word();

	const response = await username_actors.anonymous.update_username(username.toLowerCase());

	t.deepEqual(response.err, { UserAnonymous: null });
});

test('Username.update_username()::[username_actors.motoko] with invalid username => #err - UsernameInvalid', async function (t) {
	const username = fake.word();

	const response = await username_actors.motoko.update_username(username);

	t.deepEqual(response.err, { UsernameInvalid: null });
});

test('Username.update_username()::[username_actors.motoko] with taken username => #err - UsernameTaken', async function (t) {
	const username = 'mishicat';

	const response = await username_actors.motoko.update_username(username);

	t.deepEqual(response.err, { UsernameTaken: null });
});

test('Username.update_username()::[username_actors.motoko] with taken username => #ok - username', async function (t) {
	const username = fake.word();

	const response = await username_actors.motoko.update_username(username.toLowerCase());

	t.equal(response.ok.username, username.toLowerCase());
});

// get_username
test('Username.get_username()::[username_actors.mishicat]: user has username => #ok - username', async function (t) {
	const response = await username_actors.mishicat.get_username();
	const hasUsername = response.ok.username.length > 1;

	t.equal(hasUsername, true);
});

test('Username.get_username()::[username_actors.motoko]: user has username => #ok - username', async function (t) {
	const response = await username_actors.motoko.get_username();
	const hasUsername = response.ok.username.length > 1;

	t.equal(hasUsername, true);
});