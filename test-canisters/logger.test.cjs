const test = require('tape');
const { getActor } = require('../test-utils/actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const { idlFactory } = require('../.dfx/local/canisters/logger/logger.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

let logger = {};

test('Setup Actors', async function () {
	console.log('=========== Profile ===========');
	const canisterId = canisterIds.logger.local;
	let motoko_identity = Ed25519KeyIdentity.generate();

	logger = await getActor(canisterId, idlFactory, motoko_identity);
});

test('Logger: [motoko].version()', async function (t) {
	const response = await logger.version();

	t.equal(typeof response, 'bigint', 'The response should be of type number');
});

test('Logger: [motoko].authorize() - should return false meaning authorized person choosen', async function (t) {
	const response = await logger.authorize();

	t.equal(response, true);
});

test('Logger: [motoko].get_logs() - should not be authorized', async function (t) {
	const { err: error } = await logger.get_logs();

	t.deepEqual(error, { NotAuthorized: true });
});

test('Logger: [motoko].get clear_logs() - should not be authorized', async function (t) {
	const { err: error } = await logger.clear_logs();

	t.deepEqual(error, { NotAuthorized: true });
});
