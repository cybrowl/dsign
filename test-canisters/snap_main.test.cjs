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
	project_main_canister_id,
	snap_main_canister_id,
	username_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { default_identity } = require('../test-utils/identities/identity.cjs');
let mishicat_identity = Ed25519KeyIdentity.generate();
let motoko_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_images, generate_figma_asset } = require('../test-utils/utils.cjs');

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

	assets_img_staging_actors.default = await get_actor(
		assets_img_staging_canister_id,
		assets_img_staging_interface,
		default_identity
	);

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

	username_actors.default = await get_actor(
		username_canister_id,
		username_interface,
		default_identity
	);
});

test('SnapMain[mishicat].initialize_canisters()', async function (t) {
	await snap_main_actor.mishicat.initialize_canisters({
		assets_canister_id: [],
		image_assets_canister_id: [],
		snap_canister_id: [],
		project_main_canister_id: [project_main_canister_id]
	});
});

test('Username[mishicat].create_username(): with valid username => #ok - username', async function (t) {
	const username = fake.word();

	const response = await username_actors.mishicat.create_username(username.toLowerCase());

	t.equal(response.ok.username, username.toLowerCase());
});

test('SnapMain[mishicat].create_user_snap_storage(): should create initial storage for snaps => #ok - true', async function (t) {
	const response = await snap_main_actor.mishicat.create_user_snap_storage();

	t.equal(response, true);
});

test('SnapMain[mishicat].create_snap(): with no image => #err - NoImageToSave', async function (t) {
	let create_args = {
		title: 'Error NoImageToSave',
		image_cover_location: 1,
		img_asset_ids: [],
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.err, { NoImageToSave: null });
});

test('SnapMain[mishicat].create_snap(): with more than 4 images => #err - FourImagesMax', async function (t) {
	let create_args = {
		title: 'Mobile Example',
		image_cover_location: 1,
		img_asset_ids: [1, 2, 3, 4, 5],
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.err, { FourImagesMax: null });
});

test('SnapMain[mishicat].create_snap(): with invalid img asset ref => #err - AssetNotFound', async function (t) {
	let create_args = {
		title: 'Error AssetNotFound',
		image_cover_location: 1,
		img_asset_ids: [10000000],
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.err, { ErrorCall: '#AssetNotFound' });
});

test('ImageAssetStaging[mishicat].create_asset(): with image and valid identity => #ok - img_asset_ids', async function (t) {
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
	} catch (error) {
		console.log('error: ', error);
	}
});

test('Username[motoko].create_username(): with valid username => #ok - username', async function (t) {
	const username = fake.word();

	const response = await username_actors.motoko.create_username(username.toLowerCase());

	t.equal(response.ok.username, username.toLowerCase());
});

test('SnapMain[motoko].create_user_snap_storage(): should create initial storage for snaps => #ok - true', async function (t) {
	const response = await snap_main_actor.motoko.create_user_snap_storage();

	t.equal(response, true);
});

test('SnapMain[motoko].create_snap(): with invalid asset owner => #err - NotOwnerOfAsset', async function (t) {
	let create_args = {
		title: 'NotOwnerOfAsset Example',
		image_cover_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	const response = await snap_main_actor.motoko.create_snap(create_args);

	t.deepEqual(response.err, { ErrorCall: '#NotOwnerOfAsset' });
});

test('ImageAssetStaging[mishicat].get_asset(): with image and valid identity => #ok - img_asset_ids', async function (t) {
	const response = await assets_img_staging_actors.mishicat.get_asset(
		img_asset_ids[0],
		mishicat_identity.getPrincipal()
	);

	let has_asset = response.ok.created.toString().length > 0;
	t.equal(has_asset, true);
});

test('SnapMain[mishicat].create_snap(): without file asset => #ok - snap', async function (t) {
	let create_args = {
		title: 'Mobile Example',
		image_cover_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.ok, 'Created Snap');
});

test('ImageAssetStaging[mishicat].get_asset(): should return asset => #err - asset', async function (t) {
	const response = await assets_img_staging_actors.mishicat.get_asset(
		img_asset_ids[0],
		mishicat_identity.getPrincipal()
	);

	t.deepEqual(response.err, { AssetNotFound: null });
});

test('FileAssetChunks[mishicat].create_chunk(): upload chunks from file to canister => chunk_id', async function (t) {
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
	} catch (error) {
		console.log('error: ', error);
	}
});

test('SnapMain[mishicat].create_snap(): with file and images => #ok - snap', async function (t) {
	let create_args = {
		title: 'File Asset Example',
		image_cover_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: [
			{
				is_public: true,
				content_type: 'application/octet-stream',
				chunk_ids: chunk_ids
			}
		]
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.ok, 'Created Snap');
});

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
	} catch (error) {
		console.log('error: ', error);
	}
});

test('SnapMain[mishicat].create_snap(): without file asset => #ok - snap', async function (t) {
	let create_args = {
		title: 'Delete Example',
		image_cover_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.ok, 'Created Snap');
});

test('SnapMain[mishicat].delete_snaps(): with valid id => #ok - "delete_snaps"', async function (t) {
	const snap_ids = await snap_main_actor.mishicat.get_snap_ids();
	const response = await snap_main_actor.mishicat.delete_snaps([snap_ids.ok[2]]);

	t.equal(response.ok, 'Deleted Snaps');
});

test('SnapMain.get_all_snaps()', async function (t) {
	const all_snaps = await snap_main_actor.mishicat.get_all_snaps();
	const snap_ids = await snap_main_actor.mishicat.get_snap_ids();

	t.equal(all_snaps.ok.length, snap_ids.ok.length);
	t.equal(all_snaps.ok.length, 2);
	t.equal(snap_ids.ok.length, 2);
});
