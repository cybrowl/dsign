import { writable } from 'svelte/store';

export const explore_store = writable({ isFetching: false, snaps: [] });
export const explore_store_fetching = function () {
	explore_store.update(({ snaps }) => {
		return {
			isFetching: true,
			snaps: snaps
		};
	});
};

export const favorite_store = writable({ isFetching: false, snaps: [] });
export const favorite_store_fetching = function () {
	favorite_store.update(({ snaps }) => {
		return {
			isFetching: true,
			snaps: snaps
		};
	});
};

export const snap_store = writable({ isFetching: false, snaps: [] });
export const snap_store_fetching = function () {
	snap_store.update(({ snaps }) => {
		return {
			isFetching: true,
			snaps: snaps
		};
	});
};

export const project_store = writable({ isFetching: false, projects: [] });
export const project_store_fetching = function () {
	project_store.update(({ projects }) => {
		return {
			isFetching: true,
			projects: projects
		};
	});
};
