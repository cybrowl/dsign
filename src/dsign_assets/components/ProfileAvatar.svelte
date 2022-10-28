<script>
	import { onMount } from 'svelte';
	import Avatar from 'dsign-components/components/Avatar.svelte';
	import get from 'lodash/get.js';

	import { actor_profile } from '../store/actor_profile';

	import {
		is_account_settings_modal_visible,
		is_account_creation_modal_visible
	} from '../store/modal';
	import { local_storage_profile } from '../store/local_storage';

	let hasAccount = false;

	let profilePromise = $actor_profile.actor.get_profile();

	onMount(async () => {
		try {
			let {
				ok: { profile }
			} = await profilePromise;

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
			is_account_creation_modal_visible.update(
				(is_account_creation_modal_visible) => !is_account_creation_modal_visible
			);
		}
	});

	async function openSettingsModal() {
		if (hasAccount) {
			is_account_settings_modal_visible.update(
				(is_account_settings_modal_visible) => !is_account_settings_modal_visible
			);
		} else {
			is_account_creation_modal_visible.update(
				(is_account_creation_modal_visible) => !is_account_creation_modal_visible
			);
		}
	}
</script>

<Avatar
	avatar={$local_storage_profile.avatar_url}
	firstCharUsername={$local_storage_profile.username.charAt(0)}
	lastCharUsername={$local_storage_profile.username.charAt(
		$local_storage_profile.username.length - 1
	)}
	on:click={openSettingsModal}
/>

<style>
</style>
