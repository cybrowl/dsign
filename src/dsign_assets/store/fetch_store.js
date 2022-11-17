import { writable } from 'svelte/store';

export const snap_store = writable({ isFetching: false, snaps: [] });

export const project_store = writable({ isFetching: false, projects: [] });
