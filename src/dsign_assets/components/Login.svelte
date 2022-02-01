<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';
	import { createActor as createActorProfileManager } from '$ICprofile_manager';
	import { auth as authProfileManager } from '../store/profile_manager';
	import Avatar from './Avatar.svelte';

	let client;

	onMount(async () => {
		// on component load check if user logged in
		client = await AuthClient.create();

		if (await client.isAuthenticated()) {
			handleAuth();
		}
	});

	function handleAuth() {
		authProfileManager.update(() => ({
			loggedIn: true,
			actor: createActorProfileManager({
				agentOptions: {
					identity: client.getIdentity()
				}
			})
		}));
	}

	function login() {
		client.login({
			identityProvider: 'https://identity.ic0.app/#authorize',
			onSuccess: handleAuth
		});
	}
</script>

<span class="logout">
	{#if $authProfileManager.loggedIn}
		<Avatar />
	{:else}
		<button
			class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
			on:click={login}>Log In</button
		>
	{/if}
</span>

<style>
</style>
