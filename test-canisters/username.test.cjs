const test = require('tape');
const fake = require('fake-words');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

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
let bot_identity = Ed25519KeyIdentity.generate();
let anonymous_identity = null;

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let username_actors = {};

test('Setup Actors)', async function (t) {
	console.log('=========== Username ===========');

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

	username_actors.bot = await get_actor(username_canister_id, username_interface, bot_identity);

	username_actors.anonymous = await get_actor(
		username_canister_id,
		username_interface,
		anonymous_identity
	);
});

// get_username
test('Username[mishicat].get_username(): no username created => #err - UserNotFound', async function (t) {
	const response = await username_actors.mishicat.get_username();

	t.deepEqual(response.err, { UserNotFound: null });
});

test('Username[motoko].get_username(): no username created => #err - UserNotFound', async function (t) {
	const response = await username_actors.motoko.get_username();

	t.deepEqual(response.err, { UserNotFound: null });
});

// create_username
test('Username[anonymous].create_username(): with anon identity => #err - UserAnonymous', async function (t) {
	const username = fake.word();

	const response = await username_actors.anonymous.create_username(username.toLowerCase());

	t.deepEqual(response.err, { UserAnonymous: null });
});

test('Username[mishicat].create_username(): with invalid username => #err - UsernameInvalid', async function (t) {
	const username = fake.word();

	const response = await username_actors.mishicat.create_username(username);

	t.deepEqual(response.err, { UsernameInvalid: null });
});

test('Username[mishicat].create_username(): with taken username => #err - UsernameTaken', async function (t) {
	const username = fake.word();

	const { ok: created_username } = await username_actors.mishicat.create_username(
		username.toLowerCase()
	);

	const { err: err_create_username } = await username_actors.mishicat.create_username(
		username.toLowerCase()
	);

	t.equal(created_username, username.toLowerCase());
	t.deepEqual(err_create_username, { UsernameTaken: null });
});

test('Username[mishicat].create_username(): create second with new valid username => #err - UserHasUsername', async function (t) {
	const username = fake.word();

	const response = await username_actors.mishicat.create_username(username.toLowerCase());

	t.deepEqual(response.err, { UserHasUsername: null });
});

test('Username[motoko].create_username(): create first with valid username => #ok - username', async function (t) {
	const username = fake.word();

	const { ok: created_username } = await username_actors.motoko.create_username(
		username.toLowerCase()
	);

	t.equal(created_username, username.toLowerCase());
});

// update_username
// test('Username[anonymous].update_username(): with anon identity => #err - UserAnonymous', async function (t) {
// 	const username = fake.word();

// 	const response = await username_actors.anonymous.update_username(username.toLowerCase());

// 	t.deepEqual(response.err, { UserAnonymous: null });
// });

// test('Username[motoko].update_username(): with invalid username => #err - UsernameInvalid', async function (t) {
// 	const username = fake.word();

// 	const response = await username_actors.motoko.update_username(username);

// 	t.deepEqual(response.err, { UsernameInvalid: null });
// });

// test('Username[motoko].update_username(): with taken username => #err - UsernameTaken', async function (t) {
// 	const username = 'mishicat';
// 	await username_actors.bot.create_username(username);

// 	const response = await username_actors.motoko.update_username(username);

// 	t.deepEqual(response.err, { UsernameTaken: null });
// });

// test('Username[motoko].update_username(): with taken username => #ok - username', async function (t) {
// 	const username = fake.word();

// 	const response = await username_actors.motoko.update_username(username.toLowerCase());

// 	t.equal(response.ok.username, username.toLowerCase());
// });

// get_username
test('Username[mishicat].get_username(): user has username => #ok - username', async function (t) {
	const { ok: username } = await username_actors.mishicat.get_username();

	t.equal(username.length > 1, true);
});

test('Username[motoko].get_username(): user has username => #ok - username', async function (t) {
	const { ok: username } = await username_actors.motoko.get_username();

	t.equal(username.length > 1, true);
});
