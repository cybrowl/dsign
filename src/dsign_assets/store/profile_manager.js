import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory } from '$IDLprofile_manager';
import { writable } from 'svelte/store';
import environment from 'environment';

const env = environment();
console.info(env);

const isProd = env['DFX_NETWORK'] === 'ic';
const canisterId = env.canisterIds.profile_manager[env['DFX_NETWORK']];

const host = isProd
	? `https://${canisterId}.ic0.app/`
	: `http://127.0.0.1:8000`;

export function createActor(options) {
	const agentOptions = { host };

	console.log("options: ", options);
	if (options && options.agentOptions) {
		agentOptions.identity = options.agentOptions.identity;
	}

	console.log("agentOptions: ", agentOptions);

	const agent = new HttpAgent({ ...agentOptions });

	// Fetch root key for certificate validation during development
	if (!isProd) {
		agent.fetchRootKey().catch((err) => {
			console.warn('Unable to fetch root key. Check to ensure that your local replica is running');
			console.error(err);
		});
	}

	// Creates an actor with using the candid interface and the HttpAgent
	return Actor.createActor(idlFactory, {
		agent,
		canisterId
	});
}

export const profileManager = writable({
	loggedIn: false,
	actor: createActor()
});
