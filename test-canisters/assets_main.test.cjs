const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const {
	idlFactory: assets_main_interface
} = require('../.dfx/local/canisters/assets_main/assets_main.did.test.cjs');
const {
	idlFactory: assets_interface
} = require('../.dfx/local/canisters/assets/assets.did.test.cjs');
const {
	idlFactory: assets_file_chunks_interface
} = require('../.dfx/local/canisters/assets_file_chunks/assets_file_chunks.did.test.cjs');

// Canister Ids
const canister_ids = require('../.dfx/local/canister_ids.json');
const assets_main_canister_id = canister_ids.assets_main.local;
const assets_canister_id = canister_ids.assets.local;
const assets_file_chunks_canister_id = canister_ids.assets_file_chunks.local;

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');
const { generate_figma_asset } = require('../test-utils/utils.cjs');

let assets_main_actors = {};
let assets_actors = {};
let assets_file_chunks_actors = {};

let chunk_ids = [];

test('AssetsMain.version()', async function (t) {
	assets_main_actors.mishicat = await get_actor(
		assets_main_canister_id,
		assets_main_interface,
		mishicat_identity
	);

	assets_actors.mishicat = await get_actor(assets_canister_id, assets_interface, mishicat_identity);

	assets_file_chunks_actors.mishicat = await get_actor(
		assets_file_chunks_canister_id,
		assets_file_chunks_interface,
		mishicat_identity
	);
	const response = await assets_main_actors.mishicat.version();

	t.equal(typeof response, 'string');
	t.equal(response, '0.0.1');
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
});

test('FileAssetChunks.get_chunk():: initial chunk', async function (t) {
	const first_chunk = await assets_file_chunks_actors.mishicat.get_chunk(
		chunk_ids[0],
		mishicat_identity.getPrincipal()
	);

	console.log('first_chunk: ', first_chunk);
});

test('Assets.create_asset_from_chunks():: ', async function (t) {
	const asset_a = await assets_actors.mishicat.create_asset_from_chunks({
		chunk_ids,
		content_type: 'image/png',
		principal: mishicat_identity.getPrincipal()
	});

	console.log('asset_a: ', asset_a);
});

test('AssetsMain.create_asset_from_chunks():: ', async function (t) {
	const asset = await assets_main_actors.mishicat.create_asset_from_chunks({
		chunk_ids,
		content_type: 'image/png'
	});

	console.log('asset: ', asset);
});