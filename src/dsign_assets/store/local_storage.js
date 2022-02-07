import { writable } from 'svelte-local-storage-store';

// const storedTheme = localStorage.getItem('theme');
// export const theme = writable(storedTheme);

// theme.subscribe((value) => {
// 	localStorage.setItem('theme', value === 'dark' ? 'dark' : 'light');
// });

export const profileStorage = writable('profile', { username: '' });
