import { writable } from 'svelte/store';
import get from 'lodash/get';

const empty_profile = {
	created: 0n,
	username: '',
	favorites: [],
	projects: [],
	canister_id: '',
	banner: { id: '', url: '', canister_id: '' },
	is_owner: false,
	storage_metrics: [],
	avatar: { id: '', url: '', canister_id: '' }
};

export const profile_store = writable({ isFetching: false, profile: empty_profile });

export const fetching = function () {
	profile_store.update(({ profile }) => {
		return {
			isFetching: true,
			profile: profile
		};
	});
};

const update_profile_banner = function (banner) {
	profile_store.update(({ isFetching, profile }) => {
		return {
			isFetching,
			profile: {
				...profile,
				banner: {
					id: banner.id,
					url: banner.url,
					canister_id: banner.canister_id
				}
			}
		};
	});
};

const update_profile_avatar = function (avatar) {
	profile_store.update(({ isFetching, profile }) => {
		return {
			isFetching,
			profile: {
				...profile,
				avatar: {
					id: avatar.id,
					url: avatar.url,
					canister_id: avatar.canister_id
				}
			}
		};
	});
};

const update_project = function (projectId, project_name, project_description) {
	profile_store.update(({ isFetching, profile }) => {
		const updatedProjects = profile.projects.map((project) => {
			if (project.id === projectId) {
				return { ...project, name: project_name, description: project_description };
			}
			return project;
		});

		return {
			isFetching,
			profile: {
				...profile,
				projects: updatedProjects
			}
		};
	});
};

const add_project = function (newProject) {
	profile_store.update(({ isFetching, profile }) => {
		const newProjects = [...profile.projects, newProject];
		return {
			isFetching,
			profile: {
				...profile,
				projects: newProjects
			}
		};
	});
};

const delete_project = function (projectId) {
	profile_store.update(({ isFetching, profile }) => {
		const filteredProjects = profile.projects.filter((project) => project.id !== projectId);
		return {
			isFetching,
			profile: {
				...profile,
				projects: filteredProjects
			}
		};
	});
};

export const profile_actions = {
	fetching,
	update_profile_banner,
	update_profile_avatar,
	update_project,
	add_project,
	delete_project
};
