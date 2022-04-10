<script>
	import { accountSettings } from '../store/account_settings';
	import { AuthClient } from '@dfinity/auth-client';
	import { client } from '../store/client';
	import { createActor as createActorAccountSettings } from '../store/account_settings';
	import { onMount } from 'svelte';
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
			accountSettings.update(() => ({
				loggedIn: false,
				actor: createActorAccountSettings()
			}));

			removeFromStorage('profile');
		}
	});

	function handleAuth() {
		accountSettings.update(() => ({
			loggedIn: true,
			actor: createActorAccountSettings({
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
	{#if $accountSettings.loggedIn}
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
