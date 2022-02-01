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
			class="border border-solid border-purple-600 hover:bg-indigo-900 text-white py-2 px-4 rounded"
			on:click={login}>Log In</button
		>
		<button class="bg-indigo-800 hover:bg-indigo-900 text-white py-2 px-4 rounded ml-2"
			>Get Started!</button
		>
	{/if}
</span>

<style>
</style>
