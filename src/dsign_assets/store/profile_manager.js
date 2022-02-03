import { writable } from 'svelte/store';
import { createActor } from '$ICprofile_manager';

export const auth = writable({
	loggedIn: false,
	actor: createActor()
});
