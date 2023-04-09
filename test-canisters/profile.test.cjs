const test = require('tape');
const fake = require('fake-words');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

// Actor Interface
const {
	profile_interface,
	assets_img_staging_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	profile_canister_id,
	assets_img_staging_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();
let motoko_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_images } = require('../test-utils/utils.cjs');

let images = generate_images();

let assets_img_staging_actors = {};
let profile_actors = {};

let img_asset_ids = [];

test('Setup Actors', async function () {
	console.log('=========== Profile ===========');

	assets_img_staging_actors.mishicat = await get_actor(
		assets_img_staging_canister_id,
		assets_img_staging_interface,
		mishicat_identity
	);

	profile_actors.mishicat = await get_actor(
		profile_canister_id,
		profile_interface,
		mishicat_identity
	);

	profile_actors.motoko = await get_actor(profile_canister_id, profile_interface, motoko_identity);
});

test('Profile[mishicat].get_profile(): before user creates profile => #err - ProfileNotFound', async function (t) {
	const response = await profile_actors.mishicat.get_profile();

	t.deepEqual(response.err, { ProfileNotFound: true });
});

test('Profile[mishicat].create_username(): create first with valid username => #ok - username', async function (t) {
	const username = fake.word();

	const { ok: created_username } = await profile_actors.mishicat.create_username(
		username.toLowerCase()
	);

	t.equal(created_username, username.toLowerCase());
});

test('Profile[mishicat].get_profile(): after creating profile => #ok - username', async function (t) {
	const response = await profile_actors.mishicat.get_profile();

	t.equal(response.ok.username.length > 0, true);
});

test('ImageAssetStaging[mishicat].create_asset(): should create images => #ok - img_asset_ids', async function () {
	try {
		const args = {
			data: images[0],
			file_format: 'png'
		};

		let image_id = await assets_img_staging_actors.mishicat.create_asset(args);

		img_asset_ids.push(image_id);
	} catch (error) {
		console.log('error: ', error);
	}
});

test('Profile[mishicat].update_profile_avatar(): with image => #ok - updated avatar', async function (t) {
	const { ok: avatar_url } = await profile_actors.mishicat.update_profile_avatar(img_asset_ids);

	t.equal(avatar_url.length > 0, true);
});

test('ImageAssetStaging[mishicat].create_asset(): should create images => #ok - img_asset_ids', async function () {
	try {
		img_asset_ids = [];

		const args = {
			data: images[1],
			file_format: 'png'
		};

		let image_id = await assets_img_staging_actors.mishicat.create_asset(args);

		img_asset_ids.push(image_id);
	} catch (error) {
		console.log('error: ', error);
	}
});

test('Profile[mishicat].update_profile_avatar(): with new image => #ok - updated avatar', async function (t) {
	const { ok: avatar_url } = await profile_actors.mishicat.update_profile_avatar(img_asset_ids);

	t.equal(avatar_url.length > 0, true);
});
