import { Actor, HttpAgent } from '@dfinity/agent';

// imports and re-exports candid interface
import { idlFactory } from '$IDLprofile_manager';
export { idlFactory } from '$IDLprofile_manager';
import environment from 'environment';

// NOTE: this is needed to link canister/ imports. Used by dfx.config - generateCanisterAliases

const env = environment();
console.info(env);

const isProd = env['DFX_NETWORK'] === 'ic';
const canisterId = env.canisterIds.profile_manager[env['DFX_NETWORK']];

const host = isProd
	? `https://${canisterId}.ic0.app/`
	: `http://127.0.0.1:8080/?canisterId=${canisterId}`;

export const createActor = (options) => {
	const agentOptions = { host };

	if (options && options.agentOptions) {
		agentOptions.identity = options.agentOptions.identity;
	}

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
};

export const profileManager = createActor();
