const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/project_manager/project_manager.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.project_manager.local;

let projectManager = null;

test('Project Manager: version()', async function (t) {
	projectManager = await getActor(canisterId, idlFactory, Mishi);

	const response = await projectManager.version();

	console.log("version: ", response);
	t.equal(typeof response, 'string');
});
