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

export const project_store_public = writable({ isFetching: false, projects: [] });
export const project_store_public_fetching = function () {
	project_store_public.update(({ projects }) => {
		return {
			isFetching: true,
			projects: projects
		};
	});
};

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

export const projects_update = {
	delete_projects,
	rename_project
};
