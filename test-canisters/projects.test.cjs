const test = require('tape');
const fetch = require('node-fetch');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

const { getActor } = require('../tests-utils/actor.cjs');

const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/projects/projects.did.test.cjs');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.projects.local;

let projectsMain = null;

test('Projects Main: version()', async function (t) {
	projectsMain = await getActor(canisterId, idlFactory, Mishi);

	const response = await projectsMain.version();

	console.log("version: ", response);
	t.equal(typeof response, 'string');
});

test('Projects Main: heart_beat()', async function (t) {
	const response = await projectsMain.heart_beat();

	console.log("response: ", response);
});
