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

export const profile_store_fetching = function () {
	profile_store.update(({ profile }) => {
		return {
			isFetching: true,
			profile: profile
		};
	});
};
