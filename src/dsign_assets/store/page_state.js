import { writable } from 'svelte/store';

export const projects_tabs = writable({
	isSnapsSelected: true,
	isProjectsSelected: false,
	isProjectSelected: false
});

export const is_edit_active = writable(false);
