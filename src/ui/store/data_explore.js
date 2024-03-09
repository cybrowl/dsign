import { writable } from 'svelte/store';

const empty_project = {
	id: '',
	created: 0n,
	username: '',
	metrics: {
		views: 0n,
		likes: 0n
	},
	owner: [],
	name: '',
	canister_id: '',
	description: [],
	feedback: [],
	snaps: []
};

export const explore_store = writable({ isFetching: false, projects: [empty_project] });
