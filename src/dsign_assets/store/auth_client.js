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
	createActor
} from '$stores_ref/actors';

export const auth_client = writable({});

const authActors = [
	{ name: 'assets_file_staging', actor: actor_assets_file_staging },
	{ name: 'assets_img_staging', actor: actor_assets_img_staging },
	{ name: 'explore', actor: actor_explore },
	{ name: 'favorite_main', actor: actor_favorite_main },
	{ name: 'profile', actor: actor_profile },
	{ name: 'project_main', actor: actor_project_main },
	{ name: 'snap_main', actor: actor_snap_main }
];

const authenticateActor = async (actor_name, actor) => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated) {
		actor.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name,
				identity: authClient.getIdentity()
			})
		}));
	}
};

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

export const auth = {};
authActors.forEach(({ name, actor }) => {
	auth[name] = () => authenticateActor(name, actor);
});

export const auth_logout_all = async () => {
	authActors.forEach(({ name, actor }) => {
		logoutActor(name, actor);
	});
};
