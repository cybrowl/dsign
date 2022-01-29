const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const { idlFactory } = require('../.dfx/local/canisters/logger/logger.did.test.cjs');

global.fetch = fetch;

test('Logger: ping()', async function (t) {
	const canisterId = canisterIds.logger.local;
	const logger = await getActor(canisterId, idlFactory);

	const response = await logger.ping();

	t.equal(typeof response, 'string');
	t.equal(response, 'meow');
});

test('Logger: add log and get logs()', async function (t) {
	const canisterId = canisterIds.logger.local;
	const logger = await getActor(canisterId, idlFactory);

	await logger.log_event({
		time: Date.now(),
		tags: ['mishi', 'cat'],
		payload: 'executed'
	});

	const response = await logger.get_logs();

	t.equal(typeof response[0].payload, 'string');
	t.equal(response[0].payload, 'executed');
});
