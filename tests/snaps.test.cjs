const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/snaps/snaps.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const { exec } = require("child_process");

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.snaps.local;

let snapsMain = null;

test('Snaps Main: version()', async function (t) {
	snapsMain = await getActor(canisterId, idlFactory, Mishi);

	const response = await snapsMain.version();

	console.log("version: ", response);
	t.equal(typeof response, 'string');
});

test('Snaps Main: heart_beat()', async function (t) {
	const response = await snapsMain.heart_beat();

	console.log("response: ", response);
});

test('Snaps Main: create_snap()', async function (t) {
	const response = await snapsMain.create_snap("mobile", true, 1);

	console.log("create_snap: ", response);
});

test('Snaps Main: create_snap()', async function (t) {
	const response = await snapsMain.create_snap("desktop", true, 0);

	console.log("create_snap: ", response);
});

test('Snaps Main: get_snap()', async function (t) {
	const response = await snapsMain.get_snap();

	console.log("get_snap: ", response);
});

test('Logs', async function (t) {
	exec("npm run logs", (error, stdout, stderr) => {
		if (error) {
			console.log(`error: ${error.message}`);
			return;
		}
		if (stderr) {
			console.log(`stderr: ${stderr}`);
			return;
		}
		console.log(`stdout: ${stdout}`);
	});
});
