<script>
	import _ from 'lodash';
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';
	import { onMount } from 'svelte';
	import { profileManager } from '../store/profile_manager';
	import { profileStorage } from '../store/local_storage';
	import Avatar from 'dsign-components/components/Avatar.svelte';

	let hasAccount = false;

	// read local storage
	let hasAvatar = $profileStorage.avatar.length > 3 || false;
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
				avatar: _.get(profile, 'avatar', ''),
				username: _.get(profile, 'username', '')
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
	{hasAvatar}
	lastCharUsername={$profileStorage.username.charAt($profileStorage.username.length - 1)}
	on:click={handleSettingsModal}
/>

<style>
</style>
