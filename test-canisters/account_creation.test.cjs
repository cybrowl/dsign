const test = require('tape');
const { config } = require('dotenv');

config();

// Actor Interface
const {
	profile_interface,
	project_main_interface,
	snap_main_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	profile_canister_id,
	project_main_canister_id,
	snap_main_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { parseIdentity } = require('../test-utils/identities/identity.cjs');

let mishicat_identity = parseIdentity(process.env.MISHICAT_IDENTITY);
let motoko_identity = parseIdentity(process.env.MOTOKO_IDENTITY);
let default_identity = parseIdentity(process.env.DEFAULT_IDENTITY);

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let profile_actors = {};
let project_main_actor = {};
let snap_main_actor = {};

test('Setup Actors', async function () {
	console.log('=========== Account Creation ===========');

	// snap main
	snap_main_actor.mishicat = await get_actor(
		snap_main_canister_id,
		snap_main_interface,
		mishicat_identity
	);

	snap_main_actor.motoko = await get_actor(
		snap_main_canister_id,
		snap_main_interface,
		motoko_identity
	);

	snap_main_actor.default = await get_actor(
		snap_main_canister_id,
		snap_main_interface,
		default_identity
	);

	// project main
	project_main_actor.mishicat = await get_actor(
		project_main_canister_id,
		project_main_interface,
		mishicat_identity
	);

	project_main_actor.motoko = await get_actor(
		project_main_canister_id,
		project_main_interface,
		motoko_identity
	);

	project_main_actor.default = await get_actor(
		project_main_canister_id,
		project_main_interface,
		default_identity
	);

	// profile
	profile_actors.mishicat = await get_actor(
		profile_canister_id,
		profile_interface,
		mishicat_identity
	);

	profile_actors.motoko = await get_actor(profile_canister_id, profile_interface, motoko_identity);

	profile_actors.default = await get_actor(
		profile_canister_id,
		profile_interface,
		default_identity
	);
});

test('Profile[mishicat].create_username(): create first with valid username => #ok - username', async function (t) {
	const username = 'mishicat';

	const { ok: created_username } = await profile_actors.mishicat.create_username(
		username.toLowerCase()
	);

	t.equal(created_username, username.toLowerCase());
});

test('Profile[motoko].create_username(): create first with valid username => #ok - username', async function (t) {
	const username = 'motoko';

	const { ok: created_username } = await profile_actors.motoko.create_username(
		username.toLowerCase()
	);

	t.equal(created_username, username.toLowerCase());
});

test('Profile[default].create_username(): create first with valid username => #ok - username', async function (t) {
	const username = 'default';

	const { ok: created_username } = await profile_actors.default.create_username(
		username.toLowerCase()
	);

	t.equal(created_username, username.toLowerCase());
});

test('SnapMain[mishicat].create_user_snap_storage(): create initial storage for snaps => #ok - true', async function (t) {
	const response = await snap_main_actor.mishicat.create_user_snap_storage();

	t.equal(response, true);
});

test('SnapMain[motoko].create_user_snap_storage(): create initial storage for snaps => #ok - true', async function (t) {
	const response = await snap_main_actor.motoko.create_user_snap_storage();

	t.equal(response, true);
});

test('SnapMain[default].create_user_snap_storage(): create initial storage for snaps => #ok - true', async function (t) {
	const response = await snap_main_actor.default.create_user_snap_storage();

	t.equal(response, true);
});

test('ProjectMain[mishicat].create_user_project_storage(): create initial storage for projects => #ok - true', async function (t) {
	const response = await project_main_actor.mishicat.create_user_project_storage();

	t.equal(response, true);
});

test('ProjectMain[motoko].create_user_project_storage(): create initial storage for projects => #ok - true', async function (t) {
	const response = await project_main_actor.motoko.create_user_project_storage();

	t.equal(response, true);
});

test('ProjectMain[default].create_user_project_storage(): create initial storage for projects => #ok - true', async function (t) {
	const response = await project_main_actor.default.create_user_project_storage();

	t.equal(response, true);
});
