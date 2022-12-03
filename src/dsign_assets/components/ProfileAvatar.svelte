<script>
	import { onMount } from 'svelte';
	import Avatar from 'dsign-components/components/Avatar.svelte';
	import get from 'lodash/get.js';

	import { actor_profile } from '../store/actors';

	import modal_update from '$stores_ref/modal_update';
	import { local_storage_profile } from '../store/local_storage';

	let hasAccount = true;

	onMount(async () => {
		try {
			let { ok: profile, err: err_profile } = await $actor_profile.actor.get_profile();

			console.log('err_profile: ', err_profile);
			if (err_profile) {
				hasAccount = false;
			}

			// save to local storage every time
			local_storage_profile.set({
				avatar_url: get(profile, 'avatar.url', ''),
				username: get(profile, 'username', '')
			});
		} catch (error) {
			hasAccount = false;
			console.log('error: ', error);
		}

		// account creation modal should be visible when user hasn't created an account
		if (!hasAccount) {
			modal_update.change_visibility('account_creation');
		}
	});

	async function openSettingsModal() {
		if (hasAccount) {
			modal_update.change_visibility('account_settings');
		} else {
			modal_update.change_visibility('account_creation');
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
