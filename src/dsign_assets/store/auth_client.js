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

export const auth_assets_file_staging = async () => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated) {
		actor_assets_file_staging.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'assets_file_staging',
				identity: authClient.getIdentity()
			})
		}));
	}
};

export const auth_assets_img_staging = async () => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated) {
		actor_assets_img_staging.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'assets_img_staging',
				identity: authClient.getIdentity()
			})
		}));
	}
};

export const auth_explore = async () => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated) {
		actor_explore.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'explore',
				identity: authClient.getIdentity()
			})
		}));
	}
};

export const auth_favorite_main = async () => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated) {
		actor_favorite_main.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'favorite_main',
				identity: authClient.getIdentity()
			})
		}));
	}
};

export const auth_project_main = async () => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated) {
		actor_project_main.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'project_main',
				identity: authClient.getIdentity()
			})
		}));
	}
};

export const auth_snap_main = async () => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated) {
		actor_snap_main.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'snap_main',
				identity: authClient.getIdentity()
			})
		}));
	}
};

export const auth_profile = async () => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated) {
		actor_profile.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'profile',
				identity: authClient.getIdentity()
			})
		}));
	}
};

export const auth_logout_all = async () => {
	const authClient = await AuthClient.create();
	const isAuthenticated = await authClient.isAuthenticated();

	if (isAuthenticated === false) {
		actor_assets_file_staging.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'assets_file_staging',
				identity: authClient.getIdentity()
			})
		}));

		actor_assets_img_staging.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'assets_img_staging',
				identity: authClient.getIdentity()
			})
		}));

		actor_explore.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'explore',
				identity: authClient.getIdentity()
			})
		}));

		actor_profile.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'profile',
				identity: authClient.getIdentity()
			})
		}));

		actor_project_main.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'project_main',
				identity: authClient.getIdentity()
			})
		}));

		actor_favorite_main.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'favorite_main',
				identity: authClient.getIdentity()
			})
		}));

		actor_snap_main.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'snap_main',
				identity: authClient.getIdentity()
			})
		}));
	}
};
