<script>
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';
	import { onMount } from 'svelte';
	import { profileManager } from '../store/profile_manager';
	import { profileStorage } from '../store/local_storage';
	import Avatar from 'dsign-components/components/Avatar.svelte';
	import get from 'lodash/get.js';

	let hasAccount = false;

	// read local storage
	let hasUsername = $profileStorage.username.length > 0 || false;

	// call profile manager canister
	let hasAccountPromise = $profileManager.actor.has_account();
	let profilePromise = $profileManager.actor.get_profile();

	onMount(async () => {
		hasAccount = await hasAccountPromise;
		let { ok: profile } = await profilePromise;

		// read local storage directly
		if (!hasUsername) {
			//TODO: fix bug when user logout
			//TODO: set when logout/login
			profileStorage.set({
				avatar: get(profile, 'avatar', ''),
				username: get(profile, 'username', '')
			});
		}
	});

	async function handleSettingsModal() {
		if (hasAccount) {
			isSettingsActive.update((isSettingsActive) => !isSettingsActive);
		} else {
			let accountExists = await hasAccountPromise;
			!accountExists &&
				isAccountCreationActive.update((isAccountCreationActive) => !isAccountCreationActive);
		}
	}
</script>

<Avatar
	avatar={$profileStorage.avatar}
	firstCharUsername={$profileStorage.username.charAt(0)}
	lastCharUsername={$profileStorage.username.charAt($profileStorage.username.length - 1)}
	on:click={handleSettingsModal}
/>

<style>
</style>
