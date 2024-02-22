import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory as idl_assets_file_staging } from '$IDLassets_file_staging';
import { idlFactory as idl_assets_img_staging } from '$IDLassets_img_staging';
import { idlFactory as idl_explore } from '$IDLexplore';
import { idlFactory as idl_favorite_main } from '$IDLfavorite_main';
import { idlFactory as idl_profile } from '$IDLprofile';
import { idlFactory as idl_project_main } from '$IDLproject_main';
import { idlFactory as idl_snap_main } from '$IDLsnap_main';
import { idlFactory as idl_username_registry } from '$IDLusername_registry';
import { idlFactory as idl_creator } from '$IDLcreator';

import { writable } from 'svelte/store';
import environment from 'environment';

const env = environment();

let isProd = false;

if (env['DFX_NETWORK'] === 'ic' || env['DFX_NETWORK'] === 'staging') {
	isProd = true;
}

export function createActor(options) {
	// Check if options include canister_id; if not, use the default mechanism
	const canisterId = options.canister_id || env.canisterIds[options.actor_name][env['DFX_NETWORK']];

	const host = isProd ? `https://${canisterId}.icp0.io/` : `http://127.0.0.1:8080`;

	const agentOptions = { host };

	const idl_reference = {
		assets_file_staging: idl_assets_file_staging,
		assets_img_staging: idl_assets_img_staging,
		explore: idl_explore,
		favorite_main: idl_favorite_main,
		profile: idl_profile,
		project_main: idl_project_main,
		snap_main: idl_snap_main,
		creator: idl_creator,
		username_registry: idl_username_registry
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

export const actor_assets_file_staging = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'assets_file_staging' })
});

export const actor_assets_img_staging = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'assets_img_staging' })
});

export const actor_explore = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'explore' })
});

export const actor_favorite_main = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'favorite_main' })
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

export const actor_username_registry = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'username_registry' })
});

export const actor_creator = writable({
	loggedIn: false,
	actor: createActor({ actor_name: 'creator' })
});
