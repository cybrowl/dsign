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

export const profile_actions = {
	fetching,
	update_profile_banner,
	update_profile_avatar
};
