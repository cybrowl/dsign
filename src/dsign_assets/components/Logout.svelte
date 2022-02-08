<script>
	import { createActor as createActorProfileManager } from '../store/profile_manager';
	import { isSettingsActive } from '../store/modal';
	import { profileManager } from '../store/profile_manager';
	import { client } from '../store/client';

	async function logout() {
		await $client.logout();

		profileManager.update(() => ({
			loggedIn: false,
			actor: createActorProfileManager({
				agentOptions: {
					identity: $client.getIdentity()
				}
			})
		}));

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
