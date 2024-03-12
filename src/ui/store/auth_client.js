import { writable } from 'svelte/store';
import { AuthClient } from '@dfinity/auth-client';
import {
	actor_creator,
	actor_explore,
	actor_file_scaling_manager,
	actor_file_storage,
	actor_username_registry,
	createActor
} from '$stores_ref/actors';

export const auth_client = writable({});
export const auth = {};

// Init Auth
const authActors = [
	{ name: 'creator', actor: actor_creator },
	{ name: 'explore', actor: actor_explore },
	{ name: 'file_scaling_manager', actor: actor_file_scaling_manager },
	{ name: 'file_storage', actor: actor_file_storage },
	{ name: 'username_registry', actor: actor_username_registry }
];

const authenticate_actor = async (actor_name, actor, authClient, canister_id) => {
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated) {
		actor.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name,
				canister_id,
				identity: authClient.getIdentity()
			})
		}));
	} else {
		actor.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name,
				canister_id,
				identity: authClient.getIdentity()
			})
		}));
	}
};

export async function init_auth() {
	const authClient = await AuthClient.create({
		idleOptions: {
			idleTimeout: 1000 * 60 * 60 * 24 * 30,
			disableDefaultIdleCallback: true
		}
	});

	auth_client.set(authClient);

	authActors.forEach(({ name, actor }) => {
		auth[name] = (canister_id) => authenticate_actor(name, actor, authClient, canister_id);
	});
}

// Logout
const logoutActor = async (actor_name, actor) => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (!isAuthenticated) {
		actor.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name,
				identity: authClient.getIdentity()
			})
		}));
	}
};

export const auth_logout_all = async () => {
	authActors.forEach(({ name, actor }) => {
		logoutActor(name, actor);
	});
};
