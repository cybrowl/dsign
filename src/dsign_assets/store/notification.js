import { writable } from 'svelte/store';

export const notification_visible = writable({
	moving_snaps: false
});

export const notification = writable({
	project_name: ''
});
