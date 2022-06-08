const test = require('tape');
const fetch = require('node-fetch');
const fake = require('fake-words');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const lowerCase = require("lodash/lowerCase");

global.fetch = fetch;

// Actor Interface
const {
	idlFactory: profile_interface
} = require('../.dfx/local/canisters/profile/profile.did.test.cjs');
const {
	idlFactory: profile_avatar_images_interface
} = require('../.dfx/local/canisters/profile_avatar_images/profile_avatar_images.did.test.cjs');
const {
	idlFactory: username_interface
} = require('../.dfx/local/canisters/username/username.did.test.cjs');

// Canister Ids
const canister_ids = require('../.dfx/local/canister_ids.json');
const profile_canister_id = canister_ids.profile.local;
const profile_avatar_images_canister_id = canister_ids.profile_avatar_images.local;
const username_canister_id = canister_ids.username.local;

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();
let motoko_identity = Ed25519KeyIdentity.generate();
let anonymous_identity = null;

// Utils
const { generate_images } = require('../test-utils/utils.cjs');
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let avatar_images_actors = {};
let username_actors = {};
let profile_actors = {};

const username = lowerCase(fake.word());

test('ProfileAvatarImages.version()', async function (t) {
	profile_actors.mishicat = await get_actor(
		profile_canister_id,
		profile_interface,
		mishicat_identity
	);

	avatar_images_actors.mishicat = await get_actor(
		profile_avatar_images_canister_id,
		profile_avatar_images_interface,
		mishicat_identity
	);

	username_actors.mishicat = await get_actor(
		username_canister_id,
		username_interface,
		mishicat_identity
	);

	avatar_images_actors.motoko = await get_actor(
		profile_avatar_images_canister_id,
		profile_avatar_images_interface,
		motoko_identity
	);

	avatar_images_actors.anonymous = await get_actor(
		profile_avatar_images_canister_id,
		profile_avatar_images_interface,
		anonymous_identity
	);
	const response = await avatar_images_actors.mishicat.version();

	console.log('=========== Profile Avatar Images ===========');
	console.log('version: ', response);
});

test('ProfileAvatarImages.save_image()::[avatar_images_actors.mishicat]: before making profile => #err - FailedAvatarUrlUpdateProfileNotFound', async function (t) {
	const images = generate_images();
	const response = await avatar_images_actors.mishicat.save_image({content: images[0]}, username);

	t.deepEqual(response.err, { FailedAvatarUrlUpdateProfileNotFound: null });
});

test('Username.create_username()::[username_actors.mishicat] with valid username => #ok - username', async function (t) {
	const response = await username_actors.mishicat.create_username(username);

	t.equal(response.ok.username, username);
});

test('Username.get_username()::[username_actors.mishicat] => #ok - username', async function (t) {
	const response = await username_actors.mishicat.get_username();

	t.equal(response.ok.username, username);
});

test('Profile.get_profile()::[profile_actors.mishicat]  => #ok - profile', async function (t) {
	const response = await profile_actors.mishicat.get_profile();

	const hasUsername = response.ok.profile.username.length > 1;
	const hasCreated = response.ok.profile.created.toString().length > 2;
	const hasAvatarUrl = response.ok.profile.avatar_url.length > 2;


	t.equal(hasUsername, true);
	t.equal(hasCreated, true);
	t.equal(hasAvatarUrl, false);
});

test('ProfileAvatarImages.save_image()::[avatar_images_actors.mishicat]: after making profile => #ok - avatar_url', async function (t) {
	const images = generate_images();
	const response = await avatar_images_actors.mishicat.save_image({content: images[0]}, username);

	const hasAvatarUrl = response.ok.avatar_url.length > 2;

	t.equal(hasAvatarUrl, true);
});

test('Profile.get_profile()::[profile_actors.mishicat]: updated avatar_url=> #ok - profile', async function (t) {
	const response = await profile_actors.mishicat.get_profile();
	const hasUsername = response.ok.profile.username.length > 1;
	const hasCreated = response.ok.profile.created.toString().length > 2;
	const hasAvatarUrl = response.ok.profile.avatar_url.length > 2;

	t.equal(hasUsername, true);
	t.equal(hasCreated, true);
	t.equal(hasAvatarUrl, true);
});