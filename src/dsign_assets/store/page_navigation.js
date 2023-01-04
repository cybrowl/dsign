import { goto } from '$app/navigation';
import { writable } from 'svelte/store';
import { notification_visible, notification } from '$stores_ref/notification';

export const nav_items = [
	{ name: 'Explore', href: '', isSelected: false },
	{ name: 'Projects', href: 'projects', isSelected: false },
	{ name: 'Favorites', href: 'favorites', isSelected: false },
	{ name: 'Profile', href: 'profile', isSelected: false }
];

export const page_navigation = writable({
	navItems: nav_items
});

export const snap_preview = writable({});

export const navigate_to_home_with_notification = () => {
	notification_visible.set({ auth_error: true });
	notification.set({ message: 'Sign In to Access' });
	setTimeout(() => {
		notification.set({ message: '' });
		notification_visible.set({
			auth_error: false
		});
	}, 2000);

	goto('/');
};

export const show_notification_with_msg = (message) => {
	notification_visible.set({ service_error: true });
	notification.set({ message: message });
	setTimeout(() => {
		notification.set({ message: '' });
		notification_visible.set({
			auth_error: false
		});
	}, 3000);
};

function deselect_all() {
	page_navigation.update(({ navItems }) => {
		navItems.forEach((navItem) => {
			navItem.isSelected = false;
		});

		return {
			navItems: navItems
		};
	});
}

function select_item(num) {
	page_navigation.update(({ navItems }) => {
		navItems.forEach((navItem) => {
			navItem.isSelected = false;
		});
		navItems[num].isSelected = true;

		return {
			navItems: navItems
		};
	});
}

export default {
	deselect_all,
	select_item
};
