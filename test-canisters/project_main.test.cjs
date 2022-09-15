const test = require('tape');
const fake = require('fake-words');

const { Ed25519KeyIdentity } = require('@dfinity/identity');

// Actor Interface
const { project_main_interface, username_interface } = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	project_main_canister_id,
	username_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let project_main_actor = {};
let username_actors = {};

test('Setup Actors', async function (t) {
	console.log('=========== Project Main ===========');

	console.log('project_main_canister_id: ', project_main_canister_id);
	project_main_actor.mishicat = await get_actor(
		project_main_canister_id,
		project_main_interface,
		mishicat_identity
	);

	username_actors.mishicat = await get_actor(
		username_canister_id,
		username_interface,
		mishicat_identity
	);
});

test('ProjectMain[mishicat].initialize_canisters()', async function (t) {
	let response = await project_main_actor.mishicat.initialize_canisters([]);

	console.log('response', response);
});

test('Username[mishicat].create_username(): should create username => #ok - username', async function (t) {
	const username = fake.word();

	const response = await username_actors.mishicat.create_username(username.toLowerCase());

	t.equal(response.ok.username, username.toLowerCase());
});

test('ProjectMain[mishicat].create_user_project_storage(): should create initial storage for projects => #ok - true', async function (t) {
	const response = await project_main_actor.mishicat.create_user_project_storage();

	t.equal(response, true);
});

test('ProjectMain[mishicat].create_project(): with valid args => #ok - project', async function (t) {
	const snaps = [{ id: 'xxx', canister_id: 'yyy' }];
	let response = await project_main_actor.mishicat.create_project('Mishicat NFT', [snaps]);

	console.log('response', response);
});
