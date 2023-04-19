import { writable } from 'svelte/store';

export const projects_tabs = writable({
	isSnapsSelected: true,
	isProjectsSelected: false,
	isProjectSelected: false
});

export const profile_tabs = writable({
	isProjectsSelected: true,
	isFavoritesSelected: false
});

export const is_edit_active = writable(false);
