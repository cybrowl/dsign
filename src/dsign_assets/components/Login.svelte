<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';
	import Button from 'dsign-components/components/Button.svelte';
	import environment from 'environment';
	import ProfileAvatar from './ProfileAvatar.svelte';
	import { isSnapCreationModalVisible } from '../store/modal';

	import {
		createActor as create_actor_assets_file_chunks,
		actor_assets_file_chunks
	} from '../store/actor_assets_file_chunks';
	import {
		createActor as create_actor_assets_img_staging,
		actor_assets_img_staging
	} from '../store/actor_assets_img_staging';
	import { createActor as create_actor_username, actor_username } from '../store/actor_username';
	import { createActor as create_actor_profile, actor_profile } from '../store/actor_profile';
	import { createActor as create_actor_snap_main, actor_snap_main } from '../store/actor_snap_main';

	import { auth_client } from '../store/auth_client';
	import { local_storage_remove } from '../store/local_storage';

	const env = environment();
	const isProd = env['DFX_NETWORK'] === 'ic' || false;

	onMount(async () => {
		// on component load check if user logged in
		let authClient = await AuthClient.create();

		auth_client.set(authClient);

		let isAuthenticated = await authClient.isAuthenticated();

		if (isAuthenticated) {
			handleAuth();
		} else {
			actor_assets_file_chunks.update(() => ({
				loggedIn: false,
				actor: create_actor_assets_file_chunks()
			}));

			actor_assets_img_staging.update(() => ({
				loggedIn: false,
				actor: create_actor_assets_img_staging()
			}));

			actor_username.update(() => ({
				loggedIn: false,
				actor: create_actor_username()
			}));

			actor_profile.update(() => ({
				loggedIn: false,
				actor: create_actor_profile()
			}));

			actor_snap_main.update(() => ({
				loggedIn: false,
				actor: create_actor_snap_main()
			}));

			local_storage_remove('profile');
		}
	});

	function handleAuth() {
		actor_assets_file_chunks.update(() => ({
			loggedIn: true,
			actor: create_actor_assets_file_chunks({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		actor_assets_img_staging.update(() => ({
			loggedIn: true,
			actor: create_actor_assets_img_staging({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		actor_username.update(() => ({
			loggedIn: true,
			actor: create_actor_username({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		actor_profile.update(() => ({
			loggedIn: true,
			actor: create_actor_profile({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		actor_snap_main.update(() => ({
			loggedIn: true,
			actor: create_actor_snap_main({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));
	}

	function login() {
		$auth_client.login({
			identityProvider: isProd
				? 'https://identity.ic0.app/#authorize'
				: 'http://localhost:8000/?canisterId=rwlgt-iiaaa-aaaaa-aaaaa-cai',
			onSuccess: handleAuth
		});
	}

	async function openSnapCreationModal() {
		isSnapCreationModalVisible.update((isSnapCreationModalVisible) => !isSnapCreationModalVisible);
	}
</script>

<span>
	{#if $actor_username.loggedIn}
		<div class="flex items-center">
			<Button label="Upload" primary={true} class="mr-4" on:click={openSnapCreationModal} />
			<ProfileAvatar />
		</div>
	{:else}
		<Button label="Sign In" on:click={login} class="mr-4" />
		<Button primary label="Let's get started!" />
	{/if}
</span>

<style>
</style>
