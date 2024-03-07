import { persisted } from '../utils/local_storage';
import { browser } from '$app/environment';

export function local_storage_remove(key) {
	if (!browser) return;

	localStorage.removeItem(key);
}

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

export const ls_profile = persisted('profile', empty_profile);
export const ls_my_profile = persisted('my_profile', empty_profile);

// TODO: deprecate
export const local_storage_favorites = persisted('favorites', { all_favorites_count: 1 });
export const local_storage_projects = persisted('projects', { all_projects_count: 1 });
export const local_storage_snaps = persisted('snaps', { all_snaps_count: 1 });

export const local_snap_creation_design_file = persisted('design_file', {
	file_name: '',
	file_type: '',
	chunk_ids: []
});

export const local_storage_profile = persisted('profile', {
	avatar_url: '',
	banner_url: '',
	username: ''
});

export function local_storage_remove_all() {
	if (!browser) return;

	localStorage.removeItem('snaps');
	localStorage.removeItem('favorites');
	localStorage.removeItem('projects');
}
