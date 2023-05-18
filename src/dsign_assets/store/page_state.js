import { writable } from 'svelte/store';

export const projectTabsState = writable({
	isChangesSelected: false,
	isFeedbackSelected: false,
	isSnapsSelected: true
});

export const profileTabsState = writable({
	isProjectsSelected: true,
	isFavoritesSelected: false
});

export const disable_project_store_reset = writable(false);

export const is_edit_active = writable(false);
