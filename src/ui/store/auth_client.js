import { writable } from 'svelte/store';
import { AuthClient } from '@dfinity/auth-client';
import {
	actor_assets_file_staging,
	actor_assets_img_staging,
	actor_explore,
	actor_favorite_main,
	actor_profile,
	actor_project_main,
	actor_snap_main,
	actor_creator,
	actor_username_registry,
	createActor
} from '$stores_ref/actors';

export const auth_client = writable({});
export const auth = {};

// Init Auth
const authActors = [
	{ name: 'assets_file_staging', actor: actor_assets_file_staging },
	{ name: 'assets_img_staging', actor: actor_assets_img_staging },
	{ name: 'explore', actor: actor_explore },
	{ name: 'favorite_main', actor: actor_favorite_main },
	{ name: 'profile', actor: actor_profile },
	{ name: 'project_main', actor: actor_project_main },
	{ name: 'snap_main', actor: actor_snap_main },
	{ name: 'username_registry', actor: actor_username_registry },
	{ name: 'creator', actor: actor_creator }
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
