const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.profile_avatar.local;
let profileAvatar = null;

test('Profile Avatar: ping()', async function (t) {
	profileAvatar = await getActor(canisterId, idlFactory, Mishi);

	const response = await profileAvatar.ping();

	t.equal(typeof response, 'string');
	t.equal(response, 'meow');
});
