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

let assets_main_actors = {};
let assets_actors = {};
let assets_file_chunks_actors = {};

test('Assets Main: version()', async function (t) {
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
