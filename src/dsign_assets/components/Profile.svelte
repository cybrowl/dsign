<script>
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';
	import { onMount } from 'svelte';
	import { profileManager } from '../store/profile_manager';
	import { profileStorage } from '../store/local_storage';
	import Avatar from 'dsign-components/components/Avatar.svelte';
	import get from 'lodash/get.js';

	let hasAccount = false;

	// call profile manager canister
	let hasAccountPromise = $profileManager.actor.has_account();
	let profilePromise = $profileManager.actor.get_profile();

	onMount(async () => {
		try {
			// let hasAccountLocalStorage = $profileStorage.username.length > 0 || false;

			hasAccount = await hasAccountPromise;
			let { ok: profile } = await profilePromise;

			// save to local storage every time
			profileStorage.set({
				avatar: get(profile, 'avatar', ''),
				username: get(profile, 'username', '')
			});
		} catch (error) {
			console.log('error: ', error);
		}

		// account creation modal should be visible when user hasn't created an account
		if (!hasAccount) {
			isAccountCreationActive.update((isAccountCreationActive) => !isAccountCreationActive);
		}
	});

	async function openSettingsModal() {
		if (hasAccount) {
			//TODO: rename isSettingsActive to isAccountSettingsModalVisible
			isSettingsActive.update((isSettingsActive) => !isSettingsActive);
		} else {
			isAccountCreationActive.update((isAccountCreationActive) => !isAccountCreationActive);
		}
	}
</script>

<Avatar
	avatar={$profileStorage.avatar}
	firstCharUsername={$profileStorage.username.charAt(0)}
	lastCharUsername={$profileStorage.username.charAt($profileStorage.username.length - 1)}
	on:click={openSettingsModal}
/>

<style>
</style>
