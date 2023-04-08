const test = require('tape');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const { config } = require('dotenv');
const { v4: uuidv4 } = require('uuid');

config();

// Actor Interface
const { canister_ids_ledger_interface } = require('../test-utils/actor_interface.cjs');

// Canister Ids
const { canister_ids_ledger_canister_id } = require('../test-utils/actor_canister_ids.cjs');

// Identities
const { parseIdentity } = require('../test-utils/identities/identity.cjs');

let mishicat_identity = Ed25519KeyIdentity.generate();
let authorized_identity = parseIdentity(process.env.TEST_IDENTITY);

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let canister_ids_ledger_actors = {};
let id_one = uuidv4();

test('Setup Actors', async function () {
	console.log('=========== Explore ===========');

	canister_ids_ledger_actors.mishicat = await get_actor(
		canister_ids_ledger_canister_id,
		canister_ids_ledger_interface,
		mishicat_identity
	);

	canister_ids_ledger_actors.authorized = await get_actor(
		canister_ids_ledger_canister_id,
		canister_ids_ledger_interface,
		authorized_identity
	);
});

test('CanisterIdsLedger: [mishicat].version(): ', async function (t) {
	const response = await canister_ids_ledger_actors.mishicat.version();

	t.equal(typeof response, 'bigint', 'The response should be of type number');
	t.end();
});

test('CanisterIdsLedger: [mishicat].save_canister(): Not Authorized', async function (t) {
	const canister = {
		created: 1670321001063287000,
		id: id_one,
		name: 'Test',
		parent_name: 'root',
		isProd: true
	};

	const response = await canister_ids_ledger_actors.mishicat.save_canister(canister);

	t.assert(response === 'Not Authorized');
});

test('CanisterIdsLedger: [authorized].save_canister(): Added for Prod', async function (t) {
	const canister = {
		created: 1670321001063287000,
		id: id_one,
		name: 'Test',
		parent_name: 'root',
		isProd: true
	};

	const response = await canister_ids_ledger_actors.authorized.save_canister(canister);

	t.assert(response === 'Added for Prod');
});

test('CanisterIdsLedger: [authorized].save_canister(): Canister already exists', async function (t) {
	const canister = {
		created: 1670321001063287000,
		id: id_one,
		name: 'Test',
		parent_name: 'root',
		isProd: true
	};

	const response = await canister_ids_ledger_actors.authorized.save_canister(canister);

	t.assert(response === 'Canister already exists');
});

test('CanisterIdsLedger: [authorized].get_canisters(): Canisters', async function (t) {
	const response = await canister_ids_ledger_actors.authorized.get_canisters();

	t.assert(response.length > 0);
});

test('CanisterIdsLedger: [authorized].get_authorized(): include TEST_IDENTITY', async function (t) {
	const response = await canister_ids_ledger_actors.authorized.get_authorized();
	let exists = response.includes('geyca-lz2jy-mf7bx-a4tt5-o72km-wiz7y-2f57v-pwg7p-5jwzo-ol5nz-rae');

	t.equal(exists, true, 'The specified canister ID should exist in the response');
});
