import { writable } from 'svelte-local-storage-store';
import { browser } from '$app/env';

export const profileStorage = writable('profile', { avatar: '', username: '' });

export function removeFromStorage(key) {
	if (!browser) return;

	localStorage.removeItem(key);
}
