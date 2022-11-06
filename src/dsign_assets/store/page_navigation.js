import { writable } from 'svelte/store';

export const page_navigation = writable({
	navItems: [
		{ name: 'Explore', href: '', isSelected: false },
		{ name: 'Projects', href: 'projects', isSelected: false },
		{ name: 'Favorites', href: 'favorites', isSelected: false },
		{ name: 'Profile', href: 'profile', isSelected: false }
	]
});
