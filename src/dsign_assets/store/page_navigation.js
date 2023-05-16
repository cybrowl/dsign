import { goto } from '$app/navigation';
import { writable } from 'svelte/store';
import { notification_visible, notification } from '$stores_ref/notification';

export const nav_items = [
	// { name: 'Profile', href: '', isSelected: false }
];

export const page_navigation = writable({
	navigationItems: nav_items
});

export const snap_preview = writable({});
export const snap_creation = writable({});

export const navigate_to_home_with_notification = () => {
	notification_visible.set({ auth_error: true });
	notification.set({ message: 'Connect to Access' });
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

function add_item(item) {
	page_navigation.update(({ navigationItems }) => {
		const itemExists = navigationItems.some(
			(navItem) => navItem.name === item.name && navItem.href === item.href
		);

		if (!itemExists) {
			navigationItems.push(item);
		}

		return {
			navigationItems: navigationItems
		};
	});
}

function delete_all() {
	page_navigation.update(() => {
		return {
			navigationItems: []
		};
	});
}

function deselect_all() {
	page_navigation.update(({ navigationItems }) => {
		navigationItems.forEach((navItem) => {
			navItem.isSelected = false;
		});

		return {
			navigationItems: navigationItems
		};
	});
}

function select_item(num) {
	if (num > nav_items.length) {
		console.warn('num out of range');
	}

	page_navigation.update(({ navigationItems }) => {
		navigationItems.forEach((navItem) => {
			navItem.isSelected = false;
		});
		navigationItems[num].isSelected = true;

		return {
			navigationItems: navigationItems
		};
	});
}

export default {
	add_item,
	deselect_all,
	delete_all,
	select_item
};
