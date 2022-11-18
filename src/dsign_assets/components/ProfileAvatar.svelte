<script>
	import { onMount } from 'svelte';
	import Avatar from 'dsign-components/components/Avatar.svelte';
	import get from 'lodash/get.js';

	import { actor_profile } from '../store/actors';

	import { modal_visible } from '../store/modal';
	import { local_storage_profile } from '../store/local_storage';

	let hasAccount = false;

	let profilePromise = $actor_profile.actor.get_profile();

	onMount(async () => {
		try {
			let { ok: profile } = await profilePromise;

			if (profile) {
				hasAccount = true;
			}

			// save to local storage every time
			local_storage_profile.set({
				avatar_url: get(profile, 'avatar.url', ''),
				username: get(profile, 'username', '')
			});
		} catch (error) {
			console.log('error: ', error);
		}

		// account creation modal should be visible when user hasn't created an account
		if (!hasAccount) {
			modal_visible.update((options) => {
				return {
					...options,
					account_creation: !options.account_creation
				};
			});
		}
	});

	async function openSettingsModal() {
		if (hasAccount) {
			modal_visible.update((options) => {
				return {
					...options,
					account_settings: !options.account_settings
				};
			});
		} else {
			modal_visible.update((options) => {
				return {
					...options,
					account_creation: !options.account_creation
				};
			});
		}
	}
</script>

<Avatar
	avatar={$local_storage_profile.avatar_url}
	username={$local_storage_profile.username}
	on:click={openSettingsModal}
/>

<style>
</style>
