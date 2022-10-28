import { writable } from 'svelte/store';

export const modal_visible = writable({
	account_settings: false,
	account_creation: false,
	snap_creation: false,
	move_snaps: false,
	project_options: false
});
