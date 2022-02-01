<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';
	import { auth as authProfileManager } from '../store/profile_manager';

	let client;

	onMount(async () => {
		client = await AuthClient.create();
	});

	async function logout() {
		await client.logout();

		authProfileManager.update(() => ({
			loggedIn: false
		}));
	}
</script>

<div>
	{#if $authProfileManager.loggedIn}
		<div>
			<button on:click={logout}>Log out</button>
		</div>
	{:else}
		<button
			class="border border-solid border-purple-600 hover:bg-indigo-900 text-white py-2 px-4 rounded"
			on:click={logout}>Log Out</button
		>
	{/if}
</div>

<style>
</style>
