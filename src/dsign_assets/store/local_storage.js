import { writable } from 'svelte-local-storage-store';
import { browser } from '$app/environment';

export const local_storage_favorites = writable('favorites', { all_favorites_count: '1' });
export const local_storage_projects = writable('projects', { all_projects_count: '1' });
export const local_storage_snaps = writable('snaps', { all_snaps_count: '1' });

export const local_storage_profile = writable('profile', {
	avatar_url: '',
	banner_url: '',
	username: ''
});

export function local_storage_remove(key) {
	if (!browser) return;

	localStorage.removeItem(key);
}

export function local_storage_remove_all() {
	if (!browser) return;

	localStorage.removeItem('snaps');
	localStorage.removeItem('favorites');
	localStorage.removeItem('projects');
}
