<script>
	import { onMount } from 'svelte';
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';
	import { profileManager } from '../store/profile_manager';
	import { profileStorage } from '../store/local_storage';
	import _ from 'lodash';

	let hasAccount = false;
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

{#if hasAvatar}
	<img
		alt="avatar"
		class="rounded-full w-20"
		src={$profileStorage.avatar}
		on:click={handleSettingsModal}
	/>
{:else}
	<div
		class="m-2 mr-2 w-16 h-16 flex justify-center items-center rounded-full 
		bg-indigo-800 text-xl text-white uppercase cursor-pointer"
		on:click={handleSettingsModal}
	>
		<p class="cursor-pointer">
			{$profileStorage.username.charAt(0)}
			{$profileStorage.username.charAt($profileStorage.username.length - 1)}
		</p>
	</div>
{/if}

<style>
</style>
