import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory as idl_assets_file_chunks } from '$IDLassets_file_chunks';
import { idlFactory as idl_assets_img_staging } from '$IDLassets_img_staging';
import { idlFactory as idl_profile } from '$IDLprofile';
import { idlFactory as idl_project_main } from '$IDLproject_main';
import { idlFactory as idl_snap_main } from '$IDLsnap_main';
import { idlFactory as idl_username } from '$IDLusername';

import { writable } from 'svelte/store';
import environment from 'environment';

const env = environment();

const isProd = env['DFX_NETWORK'] === 'ic';

export function createActor(options) {
	const canisterIds = env.canisterIds[options.actor_name];
	const canisterId = canisterIds[env['DFX_NETWORK']];

	const host = isProd ? `https://${canisterId}.ic0.app/` : `http://127.0.0.1:8000`;

	const agentOptions = { host };

	const idl_reference = {
		assets_file_chunks: idl_assets_file_chunks,
		assets_img_staging: idl_assets_img_staging,
		profile: idl_profile,
		project_main: idl_project_main,
		snap_main: idl_snap_main,
		username: idl_username
	};

	if (options && options.identity) {
		agentOptions.identity = options.identity;
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
	return Actor.createActor(idl_reference[options.actor_name], {
		agent,
		canisterId
	});
}

export const actor_assets_file_chunks = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'assets_file_chunks' })
});

export const actor_assets_img_staging = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'assets_img_staging' })
});

export const actor_profile = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'profile' })
});

export const actor_project_main = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'project_main' })
});

export const actor_snap_main = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'snap_main' })
});

export const actor_username = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'username' })
});