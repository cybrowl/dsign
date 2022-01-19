import { writable } from 'svelte/store';
import { createActor } from '$ICprofile';

export const auth = writable({
	loggedIn: false,
	actor: createActor()
});
