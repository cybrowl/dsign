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

test('Logger: version()', async function (t) {
	const response = await logger.version();

	t.equal(typeof response, 'bigint');
	t.equal(response, 1n);
});

test('Logger: add log and get logs()', async function () {
	await logger.log_event(['mishi', 'cat'], 'Hello World!');

	const response = await logger.get_logs();

	console.log('response: ', response);
});
