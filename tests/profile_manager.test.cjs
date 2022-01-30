const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/profile_manager/profile_manager.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.profile_manager.local;
let profileManager = null;

test('Profile Manager: ping()', async function (t) {
	profileManager = await getActor(canisterId, idlFactory, Mishi);

	const response = await profileManager.ping();

	t.equal(typeof response, 'string');
	t.equal(response, 'meow');
});

test('Profile Manager: create_profile()', async function (t) {
	const username = 'Mishi';
	const response = await profileManager.create_profile(username);
	console.log('response: ', response);
});

test('Profile Manager: get_profile()', async function (t) {
	setTimeout(function () {}, 8000);

	const response = await profileManager.get_profile();

	console.log('response: ', response);
});
