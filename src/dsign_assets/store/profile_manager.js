import { writable } from 'svelte/store';
import { createActor } from '$ICprofile_manager';

export const profileManager = writable({
	loggedIn: false,
	actor: createActor()
});
