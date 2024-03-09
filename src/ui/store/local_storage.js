import { persisted } from '../utils/local_storage';
import { browser } from '$app/environment';

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

export const ls_my_profile = persisted('my_profile', empty_profile);

export function local_storage_remove_all() {
	if (!browser) return;

	localStorage.removeItem('my_profile');
}
