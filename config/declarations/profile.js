import { Actor, HttpAgent } from '@dfinity/agent';

// imports and re-exports candid interface
import { idlFactory } from '$IDLprofile';
export { idlFactory } from '$IDLprofile';
import environment from 'environment';

// NOTE: this is needed to link canister/ imports. Used by dfx.config - generateCanisterAliases

const env = environment();
console.info(env);

const canisterId = env.canisterIds.profile[env['DFX_NETWORK']];

const createActor = (canisterId, options) => {
	const agent = new HttpAgent({ host: 'http://127.0.0.1:8000/' });

	// Fetch root key for certificate validation during development
	if (env.DFX_NETWORK !== 'ic') {
		agent.fetchRootKey().catch((err) => {
			console.warn('Unable to fetch root key. Check to ensure that your local replica is running');
			console.error(err);
		});
	}

	// Creates an actor with using the candid interface and the HttpAgent
	return Actor.createActor(idlFactory, {
		agent,
		canisterId,
		...options?.actorOptions
	});
};

export const profile = createActor(canisterId);
