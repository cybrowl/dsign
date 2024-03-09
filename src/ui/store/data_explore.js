import { writable } from 'svelte/store';

export const explore_store = writable({ isFetching: false, projects: [] });
