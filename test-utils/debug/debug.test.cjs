const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

const { getActor } = require('../actor.cjs');
const canisterIds = require('../../.dfx/local/canister_ids.json');
const { idlFactory } = require('../../.dfx/local/canisters/logger/logger.did.test.cjs');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();

test('Logger: get logs()', async function (t) {
	const canisterId = canisterIds.logger.local;
	const logger = await getActor(canisterId, idlFactory, Mishi);

	const response = await logger.get_logs();

	console.log('----------------------------------');
	console.log('LOGS: ', response);
	console.log('----------------------------------');

	console.log('Length: ', response.length);
});
