import { writable } from 'svelte-local-storage-store';
import { browser } from '$app/env';


// const storedTheme = localStorage.getItem('theme');
// export const theme = writable(storedTheme);

// theme.subscribe((value) => {
// 	localStorage.setItem('theme', value === 'dark' ? 'dark' : 'light');
// });

export const profileStorage = writable('profile', { username: '' });

export function removeFromStorage(key) {
	if (!browser) return;

	localStorage.removeItem(key);
}
