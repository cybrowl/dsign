import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory } from '$IDLsnap_main';
import { writable } from 'svelte/store';
import environment from 'environment';

const env = environment();

const isProd = env['DFX_NETWORK'] === 'ic';
const canisterId = env.canisterIds.snap_main[env['DFX_NETWORK']];

const host = isProd ? `https://${canisterId}.ic0.app/` : `http://127.0.0.1:8000`;

export function createActor(options) {
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
}

export const actor_snap_main = writable({
	loggedIn: false,
	actor: createActor()
});

export const snap_storage = writable({ isFetching: false, ok: {} });