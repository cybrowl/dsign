<script>
	import { isAccountSettingsModalVisible, isAccountCreationModalVisible } from '../store/modal';
	import { onMount } from 'svelte';
	import { accountSettings } from '../store/account_settings';
	import { profileStorage } from '../store/local_storage';
	import Avatar from 'dsign-components/components/Avatar.svelte';
	import get from 'lodash/get.js';

	let hasAccount = false;

	// call profile manager canister
	let hasAccountPromise = $accountSettings.actor.has_account();
	let profilePromise = $accountSettings.actor.get_profile();

	onMount(async () => {
		try {
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
			isAccountCreationModalVisible.update((isAccountCreationModalVisible) => !isAccountCreationModalVisible);
		}
	});

	async function openSettingsModal() {
		if (hasAccount) {
			isAccountSettingsModalVisible.update(
				(isAccountSettingsModalVisible) => !isAccountSettingsModalVisible
			);
		} else {
			isAccountCreationModalVisible.update((isAccountCreationModalVisible) => !isAccountCreationModalVisible);
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
