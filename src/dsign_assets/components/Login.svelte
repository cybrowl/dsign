<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';
	import { createActor as createActorProfileManager } from '../store/profile_manager';
	import { client } from '../store/client';
	import { profileManager } from '../store/profile_manager';
	import { removeFromStorage } from '../store/local_storage';
	import Avatar from './Avatar.svelte';
	import environment from 'environment';
	import { Button } from 'dsign-component-lib';

	const env = environment();
	const isProd = env['DFX_NETWORK'] === 'ic' || false;

	onMount(async () => {
		// on component load check if user logged in
		let authClient = await AuthClient.create();

		client.set(authClient);

		let isAuthenticated = await authClient.isAuthenticated();

		if (isAuthenticated) {
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
					identity: $client.getIdentity()
				}
			})
		}));
	}

	function login() {
		$client.login({
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
		<Button label="Sign In" on:click={login} class="mr-4" />
		<Button primary label="Let’s get started!" />
	{/if}
</span>

<style>
</style>
