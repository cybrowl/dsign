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

let project_with_snaps = null;
let project_no_snaps = null;

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

test('ProjectMain[mishicat].create_project(): with snap => #ok - project', async function (t) {
	const snaps = [{ id: 'xxx', canister_id: 'yyy' }];
	const { ok } = await project_main_actor.mishicat.create_project('Mishicat NFT', [snaps]);
	project_with_snaps = ok;
});

test('ProjectMain[mishicat].create_project(): with no snaps => #ok - project', async function (t) {
	const snaps = [];
	project_no_snaps = await project_main_actor.mishicat.create_project('Mishicat NFT', snaps);
});

test('ProjectMain[mishicat].get_projects(): ', async function (t) {
	let get_response = await project_main_actor.mishicat.get_projects();
	let get_ids_response = await project_main_actor.mishicat.get_project_ids();

	console.log('get_response', get_response.ok);
	console.log('get_ids_response', get_ids_response.ok);
});

test('ProjectMain[mishicat].delete_snaps_from_project(): ', async function (t) {
	const snap = project_with_snaps.snaps[0];
	const snaps = [
		{
			id: snap.id,
			canister_id: snap.canister_id
		}
	];

	const project_ref = {
		id: project_with_snaps.id,
		canister_id: project_with_snaps.canister_id
	};

	let response = await project_main_actor.mishicat.delete_snaps_from_project(snaps, project_ref);

	console.log('response', response);
});

test('ProjectMain[mishicat].delete_projects(): ', async function (t) {
	const snaps = [];
	let create_response = await project_main_actor.mishicat.create_project('Deleted Project', snaps);
	let delete_response = await project_main_actor.mishicat.delete_projects([create_response.ok.id]);
});

test('ProjectMain[mishicat].get_projects(): ', async function (t) {
	let get_response = await project_main_actor.mishicat.get_projects();
	let get_ids_response = await project_main_actor.mishicat.get_project_ids();

	console.log('get_response', get_response.ok);
	console.log('get_ids_response', get_ids_response.ok);
});