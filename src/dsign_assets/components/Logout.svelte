<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';
	import { profileManager } from '../store/profile_manager';
	import { isSettingsActive } from '../store/modal';
	import { removeFromStorage } from '../store/local_storage';

	let client;

	onMount(async () => {
		client = await AuthClient.create();
	});

	async function logout() {
		await client.logout();

		profileManager.update(() => ({
			loggedIn: false
		}));

		removeFromStorage("profile");

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
