<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';
	import { createActor as createActorProfileManager } from '$ICprofile_manager';
	import { profileManager } from '../store/profile_manager';
	import { removeFromStorage } from '../store/local_storage';
	import Avatar from './Avatar.svelte';
	import environment from 'environment';

	let client;

	const env = environment();
	const isProd = env['DFX_NETWORK'] === 'ic' || false;

	onMount(async () => {
		// on component load check if user logged in
		client = await AuthClient.create();

		if (await client.isAuthenticated()) {
			handleAuth();
		} else {
			profileManager.update(() => ({
				loggedIn: false,
				actor: createActorProfileManager()
			}));

			removeFromStorage('profile');
		}
	});

	function handleAuth() {
		profileManager.update(() => ({
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
			identityProvider: isProd
				? 'https://identity.ic0.app/#authorize'
				: 'http://rwlgt-iiaaa-aaaaa-aaaaa-cai.localhost:8000/#authorize',
			onSuccess: handleAuth
		});
	}
</script>

<span>
	{#if $profileManager.loggedIn}
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
