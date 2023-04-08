const test = require('tape');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

// Actor Interface
const {
	assets_file_staging_interface,
	test_assets_interface
} = require('../test-utils/actor_interface.cjs');

// Canister Ids
const {
	assets_file_chunks_canister_id,
	test_assets_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_figma_asset } = require('../test-utils/utils.cjs');

let assets_actors = {};
let assets_file_chunks_actors = {};

let chunk_ids = [];

test('Setup Actors', async function (t) {
	assets_actors.mishicat = await get_actor(
		test_assets_canister_id,
		test_assets_interface,
		mishicat_identity
	);

	assets_file_chunks_actors.mishicat = await get_actor(
		assets_file_chunks_canister_id,
		assets_file_staging_interface,
		mishicat_identity
	);
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

test('FileAssetChunks.get_chunk():: return #ok => first chunk', async function (t) {
	const response = await assets_file_chunks_actors.mishicat.get_chunk(
		chunk_ids[0],
		mishicat_identity.getPrincipal()
	);

	const hasCreatedDate = response.ok.created.toString().length > 5;
	const hasOwner = response.ok.owner.toString().length > 5;
	const hasData = response.ok.data.length > 10;

	t.equal(hasCreatedDate, true);
	t.equal(hasOwner, true);
	t.equal(hasData, true);
});

test('FileAssetChunks.delete_chunks():: remove chunks from storage', async function (t) {
	assets_file_chunks_actors.mishicat.delete_chunks(chunk_ids);
});

test('Assets.create_asset_from_chunks():: return #err => Not Authorized', async function (t) {
	const response = await assets_actors.mishicat.create_asset_from_chunks({
		chunk_ids,
		content_type: 'application/octet-stream',
		is_public: true,
		principal: mishicat_identity.getPrincipal()
	});

	t.deepEqual(response.err, 'Not Authorized');
});
