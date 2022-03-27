<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { client } from '../store/client';
	import { createActor as createActorProfileManager } from '../store/profile_manager';
	import { onMount } from 'svelte';
	import { profileManager } from '../store/profile_manager';
	import { removeFromStorage } from '../store/local_storage';
	import Button from 'dsign-components/components/Button.svelte';
	import environment from 'environment';
	import ProfileAvatar from './ProfileAvatar.svelte';

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
		<div class="flex items-center">
			<Button label="Upload" primary={true} class="mr-4" />
			<ProfileAvatar />
		</div>
	{:else}
		<Button label="Sign In" on:click={login} class="mr-4" />
		<Button primary label="Let's get started!" />
	{/if}
</span>

<style>
</style>
