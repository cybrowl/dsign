<script>
	import { onMount } from 'svelte';
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';
	import { profileManager } from '../store/profile_manager';
	import { profileStorage } from '../store/local_storage';

	let profile = {
		avatar: 'http://127.0.0.1:8000/avatar/Pacom?canisterId=qoctq-giaaa-aaaaa-aaaea-cai'
	};
	let hasAccount = false;
	let hasAvatar = profile.avatar.length > 3 || false;
	let hasUsername = $profileStorage.username.length > 0 || false;

	// call profile manager canister
	let hasAccountPromise = $profileManager.actor.has_account();
	let profilePromise = $profileManager.actor.get_profile();

	onMount(async () => {
		hasAccount = await hasAccountPromise;
		({ ok: profile } = await profilePromise);

		if (!hasUsername) {
			//TODO: fix bug when user logout
			//TODO: set when logout/login
			profileStorage.set({ username: profile.username });
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
		src={profile.avatar}
		on:click={handleSettingsModal}
	/>
{:else}
	<div
		class="m-2 mr-2 w-16 h-16 flex justify-center items-center rounded-full bg-indigo-800 text-xl text-white uppercase cursor-pointer"
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
