<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';
	import Button from 'dsign-components/components/Button.svelte';
	import environment from 'environment';
	import ProfileAvatar from './ProfileAvatar.svelte';

	import { createActor as create_actor_username, actor_username } from '../store/actor_username';
	import { createActor as create_actor_profile, actor_profile } from '../store/actor_profile';
	import { createActor as create_actor_profile_avatar_main, actor_profile_avatar_main } from '../store/actor_profile_avatar_main';

	import { client } from '../store/client';
	import { local_storage_remove } from '../store/local_storage';

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
			actor_username.update(() => ({
				loggedIn: false,
				actor: create_actor_username()
			}));

			actor_profile.update(() => ({
				loggedIn: false,
				actor: create_actor_profile()
			}));

			actor_profile_avatar_main.update(() => ({
				loggedIn: false,
				actor: create_actor_profile_avatar_main()
			}));

			local_storage_remove('profile');
		}
	});

	function handleAuth() {
		actor_username.update(() => ({
			loggedIn: true,
			actor: create_actor_username({
				agentOptions: {
					identity: $client.getIdentity()
				}
			})
		}));

		actor_profile.update(() => ({
			loggedIn: true,
			actor: create_actor_profile({
				agentOptions: {
					identity: $client.getIdentity()
				}
			})
		}));

		actor_profile_avatar_main.update(() => ({
			loggedIn: true,
			actor: create_actor_profile_avatar_main({
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
				: 'http://localhost:8000/?canisterId=rwlgt-iiaaa-aaaaa-aaaaa-cai',
			onSuccess: handleAuth
		});
	}
</script>

<span>
	{#if $actor_username.loggedIn}
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
