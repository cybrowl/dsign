import { writable } from 'svelte/store';
import get from 'lodash/get';

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

export const project_store = writable({ isFetching: false, project: empty_project });
