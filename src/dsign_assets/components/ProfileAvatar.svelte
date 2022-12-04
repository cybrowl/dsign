<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import Avatar from 'dsign-components/components/Avatar.svelte';
	import get from 'lodash/get.js';

	import { actor_profile } from '../store/actors';

	import modal_update from '$stores_ref/modal_update';
	import { local_storage_profile } from '../store/local_storage';

	onMount(async () => {
		try {
			let { ok: profile, err: err_profile } = await $actor_profile.actor.get_profile();

			if (err_profile) {
				goto('/account_creation');
			}

			// save to local storage every time
			local_storage_profile.set({
				avatar_url: get(profile, 'avatar.url', ''),
				username: get(profile, 'username', '')
			});
		} catch (error) {
			goto('/');
		}
	});

	async function openSettingsModal() {
		modal_update.change_visibility('account_settings');
	}
</script>

<Avatar
	avatar={$local_storage_profile.avatar_url}
	username={$local_storage_profile.username}
	on:click={openSettingsModal}
/>

<style>
</style>
