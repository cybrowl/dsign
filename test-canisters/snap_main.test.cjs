const test = require('tape');
const fake = require('fake-words');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const { snap_main_interface, username_interface } = require('../test-utils/actor_interface.cjs');
const {
	idlFactory: assets_file_chunks_interface
} = require('../.dfx/local/canisters/assets_file_chunks/assets_file_chunks.did.test.cjs');

// Canister Ids
const {
	assets_file_chunks_canister_id,
	snap_main_canister_id,
	username_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { default_identity } = require('../test-utils/identities/identity.cjs');
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_images, generate_figma_asset } = require('../test-utils/utils.cjs');

let images = generate_images();

let assets_file_chunks_actors = {};
let snap_main_actor = {};
let username_actors = {};

let created_snap = {};
let chunk_ids = [];

test('SnapMain.assign actors()', async function (t) {
	console.log('snap_main_canister_id: ', snap_main_canister_id);

	assets_file_chunks_actors.mishicat = await get_actor(
		assets_file_chunks_canister_id,
		assets_file_chunks_interface,
		mishicat_identity
	);

	snap_main_actor.mishicat = await get_actor(
		snap_main_canister_id,
		snap_main_interface,
		mishicat_identity
	);
	snap_main_actor.default = await get_actor(
		snap_main_canister_id,
		snap_main_interface,
		default_identity
	);

	username_actors.mishicat = await get_actor(
		username_canister_id,
		username_interface,
		mishicat_identity
	);
	username_actors.default = await get_actor(
		username_canister_id,
		username_interface,
		default_identity
	);

	const response = await snap_main_actor.mishicat.version();
	t.equal(typeof response, 'string');

	console.log('=========== Snap Main ===========');
	console.log('version: ', response);
});

test('SnapMain.initialize_canisters()', async function (t) {
	await snap_main_actor.mishicat.initialize_canisters();
});

test('Username.create_username()::[username_actors.mishicat]: create first with valid username => #ok - username', async function (t) {
	const username = fake.word();

	const response = await username_actors.mishicat.create_username(username.toLowerCase());

	t.equal(response.ok.username, username.toLowerCase());
});

test('SnapMain.create_user_snap_storage()::[snap_main_actor.mishicat]: create initial storage for snaps => #ok - true', async function (t) {
	const response = await snap_main_actor.mishicat.create_user_snap_storage();

	t.equal(response, true);
});

test('FileAssetChunks.create_chunk():: upload chunks from file to canister', async function (t) {
	const uploadChunk = async ({ chunk, file_name }) => {
		return assets_file_chunks_actors.mishicat.create_chunk({
			data: [...chunk],
			file_name: file_name
		});
	};

	const figma_asset_buffer = generate_figma_asset();
	const figma_asset_unit8Array = new Uint8Array(figma_asset_buffer);

	const file_name = 'dsign_stage_1.fig';

	const promises = [];
	const chunkSize = 2000000;

	for (let start = 0; start < figma_asset_unit8Array.length; start += chunkSize) {
		const chunk = figma_asset_unit8Array.slice(start, start + chunkSize);

		promises.push(
			uploadChunk({
				file_name,
				chunk
			})
		);
	}

	chunk_ids = await Promise.all(promises);

	const hasChunkIds = chunk_ids.length > 2;
	t.equal(hasChunkIds, true);
});

test('SnapMain.create_snap()::[snap_main_actor.mishicat] => #err - too many images', async function (t) {
	let create_args = {
		title: 'mobile',
		cover_image_location: 1,
		images: [{ data: images[0] }, { data: images[1] }],
		file_asset: {
			chunk_ids: chunk_ids,
			content_type: 'application/octet-stream',
			is_public: true
		}
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.equals(response.err, 'One Image Max');
});

test('SnapMain.create_snap()', async function (t) {
	let create_args = {
		title: 'one image',
		cover_image_location: 1,
		images: [{ data: images[0] }],
		file_asset: {
			chunk_ids: chunk_ids,
			content_type: 'application/octet-stream',
			is_public: true
		}
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);
	created_snap = response.ok;

	console.log('created_snap: ', created_snap);

	t.deepEqual(response.ok.image_urls.length, 1);
});

test('SnapMain.finalize_snap_creation()', async function (t) {
	let snap_creation_promises = [];

	for (const image of images) {
		let snap_temp = {
			canister_id: created_snap.canister_id,
			snap_id: created_snap.id,
			images: [{ data: image }]
		};

		snap_creation_promises.push(snap_main_actor.mishicat.finalize_snap_creation(snap_temp));
	}

	const responses = await Promise.all(snap_creation_promises);
});

test('SnapMain.get_all_snaps()', async function (t) {
	const response = await snap_main_actor.mishicat.get_all_snaps();

	console.info('get_all_snaps: ', response.ok);
});

test('SnapMain.get_all_snaps()', async function (t) {
	const response = await snap_main_actor.mishicat.get_all_snaps();

	console.info('get_all_snaps: ', response.ok);
});
