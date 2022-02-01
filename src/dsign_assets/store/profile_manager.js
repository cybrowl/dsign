import { writable } from 'svelte/store';
import { createActor } from '$ICprofile_manager';

export const auth = writable({
	loggedIn: true,
	actor: createActor()
});
