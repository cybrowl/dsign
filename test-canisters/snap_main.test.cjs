const test = require('tape');
const { config } = require('dotenv');

config();

// Actor Interface
const {
	assets_file_staging_interface,
	assets_img_staging_interface,
	profile_interface,
	project_main_interface,
	snap_main_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	assets_file_staging_canister_id,
	assets_img_staging_canister_id,
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
const {
	generate_animal_images,
	generate_figma_asset,
	generate_figma_dsign_components,
	generate_flower_images,
	generate_motoko_image
} = require('../test-utils/utils.cjs');

let assets_file_chunks_actors = {};
let assets_img_staging_actors = {};
let profile_actor = {};
let project_main_actor = {};
let snap_main_actor = {};

let design_file_chunk_ids = [];
let img_asset_ids = [];

let projects = [];

test('Setup Actors', async function () {
	console.log('=========== Snap Main ===========');

	assets_file_chunks_actors.mishicat = await get_actor(
		assets_file_staging_canister_id,
		assets_file_staging_interface,
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

	project_main_actor.mishicat = await get_actor(
		project_main_canister_id,
		project_main_interface,
		mishicat_identity
	);

	profile_actor.mishicat = await get_actor(
		profile_canister_id,
		profile_interface,
		mishicat_identity
	);

	profile_actor.motoko = await get_actor(profile_canister_id, profile_interface, motoko_identity);

	profile_actor.default = await get_actor(profile_canister_id, profile_interface, default_identity);
});

test('ProjectMain[mishicat].delete_all_projects(): with valid project ids => #ok - "Deleted Projects"', async function (t) {
	const { ok: ids } = await project_main_actor.mishicat.get_project_ids();

	if (ids.length > 0) {
		const response = await project_main_actor.mishicat.delete_projects(ids);

		t.equal(response.ok, 'Deleted Projects');
	} else {
		t.equal(ids.length, 0);
	}
});

test('ProjectMain[mishicat].create_project(): with name => #ok - project', async function (t) {
	let { ok: projects_before } = await project_main_actor.mishicat.get_all_projects([]);

	if (projects_before.length === 0) {
		await project_main_actor.mishicat.create_project('Project One', []);

		let { ok: projects_, err: error } = await project_main_actor.mishicat.get_all_projects([]);

		projects = projects_;

		t.true(projects.length > 0);
		t.equal(error, undefined);
	}
});

test('SnapMain[mishicat].create_snap(): with no image => #err - NoImageToSave', async function (t) {
	let create_args = {
		title: 'Error NoImageToSave',
		project: {
			id: projects[0].id,
			canister_id: projects[0].canister_id
		},
		image_cover_location: 1,
		img_asset_ids: [],
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.err, { NoImageToSave: null });
});

test('SnapMain[mishicat].create_snap(): with more than 12 images => #err - TwelveMax', async function (t) {
	let create_args = {
		title: 'Mobile Example',
		project: {
			id: projects[0].id,
			canister_id: projects[0].canister_id
		},
		image_cover_location: 1,
		img_asset_ids: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.err, { TwelveMax: null });
});

test('SnapMain[mishicat].create_snap(): with invalid img asset ref => #err - AssetNotFound', async function (t) {
	let create_args = {
		title: 'Error AssetNotFound',
		project: {
			id: projects[0].id,
			canister_id: projects[0].canister_id
		},
		image_cover_location: 1,
		img_asset_ids: [10000000],
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.err, { ErrorCall: '#AssetNotFound' });
});

test('ImageAssetStaging[mishicat].create_asset(): with image and valid identity => #ok - img_asset_ids', async function () {
	let promises = [];
	let images = generate_flower_images();

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

test('SnapMain[motoko].create_snap(): with invalid asset owner => #err - NotOwnerOfAsset', async function (t) {
	let create_args = {
		title: 'NotOwnerOfAsset Example',
		project: {
			id: projects[0].id,
			canister_id: projects[0].canister_id
		},
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

test('SnapMain[mishicat].delete_snaps(): with valid id => #ok - "delete_snaps"', async function (t) {
	const { ok: all_snap_ids } = await snap_main_actor.mishicat.get_snap_ids();
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();

	if (all_snap_ids.length > 0) {
		const project_ref = all_snaps[0].project_ref[0];

		const response = await snap_main_actor.mishicat.delete_snaps(all_snap_ids, project_ref);

		t.equal(response.ok, 'Deleted Snaps');
	} else {
		t.equal(all_snaps.length, 0);
		t.equal(all_snap_ids.length, 0);
	}
});

test('SnapMain.get_all_snaps(): zero snaps => #ok length 0', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const { ok: all_snap_ids } = await snap_main_actor.mishicat.get_snap_ids();

	t.equal(all_snaps.length, 0);
	t.equal(all_snap_ids.length, 0);
});

test('SnapMain[mishicat].create_snap(): with images only => #ok - snap', async function (t) {
	let create_args = {
		title: 'snap example one',
		project: {
			id: projects[0].id,
			canister_id: projects[0].canister_id
		},
		image_cover_location: 1,
		img_asset_ids: img_asset_ids,
		file_asset: []
	};

	const response = await snap_main_actor.mishicat.create_snap(create_args);

	t.deepEqual(response.ok, 'Created Snap');
});

test('ImageAssetStaging[mishicat].get_asset():  => #err - no image found', async function (t) {
	const response = await assets_img_staging_actors.mishicat.get_asset(
		img_asset_ids[0],
		mishicat_identity.getPrincipal()
	);

	t.deepEqual(response.err, { AssetNotFound: null });
});

test('SnapMain[mishicat].edit_snap(): name only => #ok - edited snap', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const snap = all_snaps[0];

	let create_args = {
		title: ['snap example renamed'],
		id: snap.id,
		canister_id: snap.canister_id,
		image_cover_location: [],
		img_asset_ids: [],
		file_asset: []
	};

	const { ok: snap_ } = await snap_main_actor.mishicat.edit_snap(create_args);

	t.deepEqual(snap_.title, 'snap example renamed');
	t.deepEqual(snap_.owner, []);
	t.equal(snap_.images.length, 3);
});

test('ImageAssetStaging[mishicat].create_asset(): with image and valid identity => #ok - img_asset_ids', async function () {
	let promises = [];
	let images = generate_animal_images();

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

test('SnapMain[mishicat].edit_snap(): name and images => #ok - edited snap', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const snap = all_snaps[0];

	let create_args = {
		title: ['snap example animals'],
		id: snap.id,
		canister_id: snap.canister_id,
		image_cover_location: [],
		img_asset_ids: [img_asset_ids],
		file_asset: []
	};

	const { ok: snap_ } = await snap_main_actor.mishicat.edit_snap(create_args);

	t.deepEqual(snap_.title, 'snap example animals');
	t.deepEqual(snap_.owner, []);
	t.equal(snap_.images.length, 5);
});

test('ImageAssetStaging[mishicat].create_asset(): with image and valid identity => #ok - img_asset_ids', async function () {
	let promises = [];
	let images = generate_motoko_image();

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

test('SnapMain[mishicat].edit_snap(): images only => #ok - edited snap', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const snap = all_snaps[0];

	let create_args = {
		title: [],
		id: snap.id,
		canister_id: snap.canister_id,
		image_cover_location: [],
		img_asset_ids: [img_asset_ids],
		file_asset: []
	};

	const { ok: snap_ } = await snap_main_actor.mishicat.edit_snap(create_args);

	t.deepEqual(snap_.title, 'snap example animals');
	t.deepEqual(snap_.owner, []);
	t.equal(snap_.images.length, 6);
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

	design_file_chunk_ids = await Promise.all(promises);

	const hasChunkIds = design_file_chunk_ids.length > 2;
	t.equal(hasChunkIds, true);
});

test('SnapMain[mishicat].edit_snap(): file only => #ok - snap', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const snap = all_snaps[0];

	let create_args = {
		title: [],
		id: snap.id,
		canister_id: snap.canister_id,
		image_cover_location: [],
		img_asset_ids: [],
		file_asset: [
			{
				is_public: true,
				content_type: 'application/octet-stream',
				chunk_ids: design_file_chunk_ids
			}
		]
	};

	const { ok: snap_ } = await snap_main_actor.mishicat.edit_snap(create_args);

	t.equal(snap_.file_asset.id.length > 3, true);
	t.equal(snap_.file_asset.file_name, 'dsign_stage_1.fig');
});

test('FileAssetChunks[mishicat].create_chunk(): upload chunks from file to canister => chunk_id', async function (t) {
	const uploadChunk = async ({ chunk, file_name }) => {
		return assets_file_chunks_actors.mishicat.create_chunk({
			data: [...chunk],
			file_name: file_name
		});
	};

	const figma_asset_buffer = generate_figma_dsign_components();
	const figma_asset_unit8Array = new Uint8Array(figma_asset_buffer);

	const file_name = 'dsign_components.fig';

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

	design_file_chunk_ids = await Promise.all(promises);

	const hasChunkIds = design_file_chunk_ids.length > 2;
	t.equal(hasChunkIds, true);
});

test('SnapMain[mishicat].edit_snap(): file only => #err - SnapIdsDoNotMatch', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const snap = all_snaps[0];

	let create_args = {
		title: [],
		id: snap.id,
		canister_id: snap.canister_id,
		image_cover_location: [],
		img_asset_ids: [],
		file_asset: [
			{
				is_public: true,
				content_type: 'application/octet-stream',
				chunk_ids: design_file_chunk_ids
			}
		]
	};

	const { ok: snap_, err: error_ } = await snap_main_actor.motoko.edit_snap(create_args);

	t.deepEqual(error_, { SnapIdsDoNotMatch: null });
	t.equal(snap_, undefined);
});

test('SnapMain[mishicat].edit_snap(): file only => #ok - snap', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const snap = all_snaps[0];

	let create_args = {
		title: [],
		id: snap.id,
		canister_id: snap.canister_id,
		image_cover_location: [],
		img_asset_ids: [],
		file_asset: [
			{
				is_public: true,
				content_type: 'application/octet-stream',
				chunk_ids: design_file_chunk_ids
			}
		]
	};

	const { ok: snap_ } = await snap_main_actor.mishicat.edit_snap(create_args);

	t.equal(snap_.file_asset.id.length > 3, true);
	t.equal(snap_.file_asset.file_name, 'dsign_components.fig');
});

test('SnapMain[mishicat].edit_snap(): all empty => #ok - snap', async function (t) {
	const { ok: all_snaps } = await snap_main_actor.mishicat.get_all_snaps();
	const snap = all_snaps[0];

	let create_args = {
		title: [],
		id: snap.id,
		canister_id: snap.canister_id,
		image_cover_location: [],
		img_asset_ids: [],
		file_asset: []
	};

	const { ok: snap_ } = await snap_main_actor.mishicat.edit_snap(create_args);

	t.equal(snap_.file_asset.id.length > 3, true);
	t.equal(snap_.file_asset.file_name, 'dsign_components.fig');
});
