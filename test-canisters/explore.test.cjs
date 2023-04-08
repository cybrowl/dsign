// const test = require('tape');
// const { Ed25519KeyIdentity } = require('@dfinity/identity');

// // Actor Interface
// const { explore_interface } = require('../test-utils/actor_interface.cjs');

// // Canister Ids
// const { explore_canister_id } = require('../test-utils/actor_canister_ids.cjs');

// // Identities
// let mishicat_identity = Ed25519KeyIdentity.generate();
// let motoko_identity = Ed25519KeyIdentity.generate();

// // Utils
// const { getActor: get_actor } = require('../test-utils/actor.cjs');

// let explore_actors = {};

// test('Setup Actors', async function (t) {
// 	console.log('=========== Explore ===========');

// 	explore_actors.mishicat = await get_actor(
// 		explore_canister_id,
// 		explore_interface,
// 		mishicat_identity
// 	);

// 	explore_actors.motoko = await get_actor(explore_canister_id, explore_interface, motoko_identity);
// });

// test('Explore[mishicat].length(): ', async function (t) {
// 	const response = await explore_actors.mishicat.length();

// 	console.log('Response: ', response);
// });

// test('Explore[mishicat].get_all_snaps(): ', async function (t) {
// 	const response = await explore_actors.mishicat.get_all_snaps();

// 	console.log('Response: ', response);
// });
