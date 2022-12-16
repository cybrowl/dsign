const test = require('tape');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

// Actor Interface
const { health_metrics_interface } = require('../test-utils/actor_interface.cjs');

// Canister Ids
const { health_metrics_canister_id } = require('../test-utils/actor_canister_ids.cjs');

// Identities
let mishicat_identity = Ed25519KeyIdentity.generate();
let motoko_identity = Ed25519KeyIdentity.generate();

// Utils
const { getActor: get_actor } = require('../test-utils/actor.cjs');

let health_metrics_actors = {};

test('Setup Actors', async function (t) {
	console.log('=========== Explore ===========');

	health_metrics_actors.mishicat = await get_actor(
		health_metrics_canister_id,
		health_metrics_interface,
		mishicat_identity
	);

	health_metrics_actors.motoko = await get_actor(
		health_metrics_canister_id,
		health_metrics_interface,
		motoko_identity
	);
});

test('HealthMetrics[mishicat].length(): ', async function (t) {
	const response = await health_metrics_actors.mishicat.version();

	console.log('Response: ', response);
});

test('HealthMetrics[mishicat].get_logs(): ', async function (t) {
	const response = await health_metrics_actors.mishicat.get_latest_logs(2);

	// loop and log response
	for (let i = 0; i < response.length; i++) {
		console.log('Response: ', response[i]);
	}
	console.log('Response: ', response);
});
