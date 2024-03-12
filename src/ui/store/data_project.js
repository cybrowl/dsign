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
export const is_edit_active = writable(false);

export const fetching = function () {
	project_store.update(({ project }) => {
		return {
			isFetching: true,
			project: project
		};
	});
};

export const deselect_snaps = function () {
	project_store.update(({ isFetching, project }) => {
		const snaps = get(project, 'snaps', []).map((snap) => ({
			...snap,
			isSelected: false
		}));

		return {
			isFetching,
			project: {
				...project,
				snaps
			}
		};
	});
};

export const get_selected_snap_ids = () => {
	let selectedSnapIds = [];

	project_store.subscribe(({ project }) => {
		const snaps = get(project, 'snaps', []);

		// Filter for snaps that are selected and map to their IDs
		selectedSnapIds = snaps.filter((snap) => snap.isSelected).map((snap) => snap.id);
	});

	return selectedSnapIds;
};

export const remove_selected_snaps = () => {
	project_store.update(({ isFetching, project }) => {
		const selectedSnapIds = project.snaps.filter((snap) => snap.isSelected).map((snap) => snap.id);
		const filteredSnaps = project.snaps.filter((snap) => !selectedSnapIds.includes(snap.id));

		return {
			isFetching,
			project: {
				...project,
				snaps: filteredSnaps
			}
		};
	});
};

export const update_project = (updatedProject) => {
	project_store.update(() => {
		return {
			isFetching: false,
			project: updatedProject
		};
	});
};

export const project_actions = {
	fetching,
	deselect_snaps,
	get_selected_snap_ids,
	remove_selected_snaps,
	update_project
};
