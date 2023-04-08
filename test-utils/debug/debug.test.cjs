const test = require('tape');
const { config } = require('dotenv');

const { getActor } = require('../actor.cjs');
const canisterIds = require('../../.dfx/local/canister_ids.json');
const { idlFactory } = require('../../.dfx/local/canisters/logger/logger.did.test.cjs');
const { parseIdentity } = require('../identities/identity.cjs');

config();

let authorized_identity = parseIdentity(process.env.LOGGER_IDENTITY);

test('Logger: get logs()', async function (t) {
	const canisterId = canisterIds.logger.local;
	const logger = await getActor(canisterId, idlFactory, authorized_identity);

	const response = await logger.get_logs();

	console.log('----------------------------------');
	console.log('LOGS: ', response);
	console.log('----------------------------------');

	console.log('Length: ', response.length);
});
