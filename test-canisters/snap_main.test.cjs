const test = require('tape');
const fake = require('fake-words');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const {
	assets_file_chunks_interface,
	assets_img_staging_interface,
	snap_main_interface,
	username_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	assets_file_chunks_canister_id,
	assets_img_staging_canister_id,
	snap_main_canister_id,
	username_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { default_identity } = require('../test-utils/identities/identity.cjs');
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_images } = require('../test-utils/utils.cjs');

let images = generate_images();

let assets_file_chunks_actors = {};
let assets_img_staging_actors = {};
let snap_main_actor = {};
let username_actors = {};

let created_snap = {};
let chunk_ids = [];
let img_asset_ids = [];

test('Setup Actors', async function (t) {
	console.log('=========== Snap Main ===========');

	assets_file_chunks_actors.mishicat = await get_actor(
		assets_file_chunks_canister_id,
		assets_file_chunks_interface,
		mishicat_identity
	);

	assets_img_staging_actors.mishicat = await get_actor(
		assets_img_staging_canister_id,
		assets_img_staging_interface,
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
});

test('SnapMain[mishicat].initialize_canisters()', async function (t) {
	await snap_main_actor.mishicat.initialize_canisters();
});

test('Username[mishicat].create_username(): should create username => #ok - username', async function (t) {
	const username = fake.word();

	const response = await username_actors.mishicat.create_username(username.toLowerCase());

	t.equal(response.ok.username, username.toLowerCase());
});

test('SnapMain[mishicat].create_user_snap_storage(): should create initial storage for snaps => #ok - true', async function (t) {
	const response = await snap_main_actor.mishicat.create_user_snap_storage();

	t.equal(response, true);
});

// test('FileAssetChunks.create_chunk():: upload chunks from file to canister', async function (t) {
// 	const uploadChunk = async ({ chunk, file_name }) => {
// 		return assets_file_chunks_actors.mishicat.create_chunk({
// 			data: [...chunk],
// 			file_name: file_name
// 		});
// 	};

// 	const figma_asset_buffer = generate_figma_asset();
// 	const figma_asset_unit8Array = new Uint8Array(figma_asset_buffer);

// 	const file_name = 'dsign_stage_1.fig';

// 	const promises = [];
// 	const chunkSize = 2000000;

// 	for (let start = 0; start < figma_asset_unit8Array.length; start += chunkSize) {
// 		const chunk = figma_asset_unit8Array.slice(start, start + chunkSize);

// 		promises.push(
// 			uploadChunk({
// 				file_name,
// 				chunk
// 			})
// 		);
// 	}

// 	chunk_ids = await Promise.all(promises);

// 	const hasChunkIds = chunk_ids.length > 2;
// 	t.equal(hasChunkIds, true);
// });

test('ImageAssetStaging[mishicat].create_asset(): should create images => #ok - img_asset_ids', async function (t) {
	let promises = [];

	images.forEach(async function (image) {
		const args = {
			data: image,
			file_format: 'png'
		};

		promises.push(assets_img_staging_actors.mishicat.create_asset(args));
	});

	try {
		img_asset_ids = await Promise.all(promises);
		console.log('asset_ids: ', img_asset_ids);
	} catch (error) {
		console.log('error: ', error);
	}
});

test('SnapMain[mishicat].create_snap(): should create snap => #ok - snap', async function (t) {
	let create_args = {
		title: 'Mobile Example',
		cover_image_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	console.info('response: ', response);
	console.log('images: ', response.ok.images);

	// t.equals(response.err, 'One Image Max');
});

test('SnapMain[mishicat].create_snap(): should return error => #err - No Image To Save', async function (t) {
	let create_args = {
		title: 'Error No Image To Save',
		cover_image_location: 1,
		img_asset_ids: [],
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	console.info('response: ', response);
});

test('SnapMain[mishicat].create_snap(): should return error => #err - AssetNotFound', async function (t) {
	let create_args = {
		title: 'Error AssetNotFound',
		cover_image_location: 1,
		img_asset_ids: [69],
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	console.info('response: ', response);
});

// test('SnapMain.create_snap()', async function (t) {
// 	let create_args = {
// 		title: 'one image',
// 		cover_image_location: 1,
// 		images: [{ data: images[0] }],
// 		file_asset: {
// 			chunk_ids: chunk_ids,
// 			content_type: 'application/octet-stream',
// 			is_public: true
// 		}
// 	};

// 	const response = await snap_main_actor.mishicat.create_snap(create_args);
// 	created_snap = response.ok;

// 	console.log('created_snap: ', created_snap);

// 	t.deepEqual(response.ok.image_urls.length, 1);
// });

// test('SnapMain.get_all_snaps()', async function (t) {
// 	const response = await snap_main_actor.mishicat.get_all_snaps();

// 	console.info('get_all_snaps: ', response.ok);
// });
