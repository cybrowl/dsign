import { writable } from 'svelte/store';

export const notification_visible = writable({
	moving_snaps: false,
	auth_error: false
});

export const notification = writable({
	hide_delay_sec: 5000,
	project_name: '',
	message: ''
});
