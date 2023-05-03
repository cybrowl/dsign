import { writable } from 'svelte/store';
import get from 'lodash/get';

export const explore_store = writable({ isFetching: false, projects: [] });
export const explore_store_fetching = function () {
	explore_store.update(({ projects }) => {
		return {
			isFetching: true,
			projects: projects
		};
	});
};

export const favorite_store = writable({ isFetching: false, projects: [] });
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

export const project_store = writable({ isFetching: false, projects: [], project: {} });
export const project_store_fetching = function () {
	project_store.update(() => {
		return {
			isFetching: true,
			projects: [],
			project: {}
		};
	});
};

function delete_favorite(favorite) {
	favorite_store.update(({ projects }) => {
		const updated_projects = projects.filter((project_) => {
			return project_.id !== favorite.id;
		});

		return {
			isFetching: false,
			projects: updated_projects
		};
	});
}

function delete_projects(project) {
	const project_snaps_ids = project.snaps.map((snap) => snap.id);

	project_store.update(({ projects }) => {
		const updated_projects = projects.filter((project_) => {
			return project_.id !== project.id;
		});

		return {
			isFetching: false,
			projects: updated_projects
		};
	});

	return project_snaps_ids;
}

function rename_project(project, project_name) {
	project_store.update(({ projects }) => {
		const updated_projects = projects.map((project_) => {
			if (project_.id === project.id) {
				return {
					...project_,
					name: project_name
				};
			}

			return project_;
		});

		return {
			isFetching: false,
			projects: updated_projects
		};
	});
}

function update_project(project) {
	project_store.update(({ projects }) => {
		return {
			isFetching: false,
			projects: projects,
			project: project
		};
	});
}

function deselect_snaps_from_project() {
	project_store.update(({ projects, project }) => {
		const snaps = get(project, 'snaps', []);

		const updated_snaps = snaps.map((snap) => {
			return {
				...snap,
				isSelected: false
			};
		});

		return {
			isFetching: false,
			projects: projects,
			project: { ...project, snaps: updated_snaps }
		};
	});
}

function delete_snaps_from_project(snaps_kept) {
	project_store.update(({ projects, project }) => {
		return {
			isFetching: false,
			projects: projects,
			project: { ...project, snaps: snaps_kept }
		};
	});
}

function update_projects(projects) {
	project_store.update(({ project }) => {
		return {
			isFetching: false,
			projects: projects,
			project: project
		};
	});
}

export const projects_update = {
	delete_projects,
	rename_project,
	delete_snaps_from_project,
	deselect_snaps_from_project,
	update_project,
	update_projects
};

export const favorites_update = {
	delete_favorite
};
