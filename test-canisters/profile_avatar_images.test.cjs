const test = require('tape');
const fetch = require('node-fetch');
const fake = require('fake-words');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const {
	idlFactory: profile_avatar_images_interface
} = require('../.dfx/local/canisters/profile_avatar_images/profile_avatar_images.did.test.cjs');

// Canister Ids
const canister_ids = require('../.dfx/local/canister_ids.json');
const profile_avatar_images_canister_id = canister_ids.profile_avatar_images.local;

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();
let motoko_identity = Ed25519KeyIdentity.generate();
let anonymous_identity = null;

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let avatar_images_actors = {};

test('ProfileAvatarImages.version()', async function (t) {
	avatar_images_actors.mishicat = await get_actor(
		profile_avatar_images_canister_id,
		profile_avatar_images_interface,
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
