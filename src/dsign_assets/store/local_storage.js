import { writable } from 'svelte-local-storage-store';
import { browser } from '$app/env';

export const local_storage_profile = writable('profile', { avatar_url: '', username: '' });

export function local_storage_remove(key) {
	if (!browser) return;

	localStorage.removeItem(key);
}
