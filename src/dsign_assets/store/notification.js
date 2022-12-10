import { writable } from 'svelte/store';

export const notification_visible = writable({
	auth_error: false,
	moving_snaps: false,
	service_error: false
});

export const notification = writable({
	hide_delay_sec: 10000,
	project_name: '',
	message: ''
});

function show_notification_snap_move(selected_project) {
	const hide_notification_delay_sec = 10000;

	notification_visible.set({
		moving_snaps: true
	});

	notification.set({
		hide_delay_sec: hide_notification_delay_sec,
		project_name: selected_project.name
	});

	setTimeout(() => {
		notification_visible.set({
			moving_snaps: false
		});
	}, hide_notification_delay_sec);
}

export const notification_update = {
	show_notification_snap_move
};
