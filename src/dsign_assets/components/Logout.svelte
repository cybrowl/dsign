<script>
	import { createActor, profileManager } from '../store/profile_manager';
	import { isSettingsActive } from '../store/modal';
	import { removeFromStorage } from '../store/local_storage';
	import { client } from '../store/client';
	import Button from 'dsign-components/components/Button.svelte';

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
		<Button label="Log Out" on:click={logout} />
	{/if}
</div>

<style>
</style>
