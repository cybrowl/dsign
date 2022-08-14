import { writable } from 'svelte/store';

export const page_navigation = writable({
	navItems: [
		{ name: 'explore', href: '', isSelected: false },
		{ name: 'projects', href: 'projects', isSelected: false },
		{ name: 'favorites', href: 'favorites', isSelected: false },
		{ name: 'profile', href: 'profile', isSelected: false }
	]
});
