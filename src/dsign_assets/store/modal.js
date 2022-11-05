import { writable } from 'svelte/store';

export const modal_visible = writable({
	account_settings: false,
	account_creation: false,
	snap_creation: false,
	snaps_move: false,
	project_creation: false,
	project_options: false,
	project_rename: false
});
