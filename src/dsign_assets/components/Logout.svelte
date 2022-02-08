<script>
	import { createActor, profileManager } from '../store/profile_manager';
	import { isSettingsActive } from '../store/modal';
	import { removeFromStorage } from '../store/local_storage';
	import { client } from '../store/client';

	async function logout() {
		await $client.logout();

		profileManager.update(() => ({
			loggedIn: false,
			actor: createActor({
				agentOptions: {
					identity: $client.getIdentity()
				}
			})
		}));

		removeFromStorage('profile');

		isSettingsActive.update((isSettingsActive) => !isSettingsActive);
	}
</script>

<div>
	{#if $profileManager.loggedIn}
		<button
			class="border border-solid border-purple-600 hover:bg-indigo-900 text-white py-2 px-4 rounded"
			on:click={logout}>Log Out</button
		>
	{/if}
</div>

<style>
</style>
