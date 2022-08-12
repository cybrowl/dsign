const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

// Actor Interface
const {
	idlFactory: assets_main_interface
} = require('../.dfx/local/canisters/assets_main/assets_main.did.test.cjs');

// Canister Ids
const canister_ids = require('../.dfx/local/canister_ids.json');
const assets_main_canister_id = canister_ids.assets_main.local;

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let assets_main_actors = {};

test('Assets Main: version()', async function (t) {
	assets_main_actors.mishicat = await get_actor(
		assets_main_canister_id,
		assets_main_interface,
		mishicat_identity
	);

	const response = await assets_main_actors.mishicat.version();

	t.equal(typeof response, 'string');
	t.equal(response, '0.0.1');
});
