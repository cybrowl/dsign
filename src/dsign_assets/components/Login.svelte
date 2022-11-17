<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';
	import Button from 'dsign-components/components/Button.svelte';
	import environment from 'environment';
	import ProfileAvatar from './ProfileAvatar.svelte';
	import { modal_visible } from '../store/modal';

	import {
		actor_assets_file_chunks,
		actor_assets_img_staging,
		actor_profile,
		actor_project_main,
		actor_snap_main,
		actor_username,
		createActor
	} from '../store/actors';

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
			actor_assets_file_chunks.update((args) => ({
				...args,
				loggedIn: false
			}));

			actor_assets_img_staging.update((args) => ({
				...args,
				loggedIn: false
			}));

			actor_username.update((args) => ({
				...args,
				loggedIn: false
			}));

			actor_profile.update((args) => ({
				...args,
				loggedIn: false
			}));

			actor_project_main.update((args) => ({
				...args,
				loggedIn: false
			}));

			actor_snap_main.update((args) => ({
				...args,
				loggedIn: false
			}));

			local_storage_remove('profile');
			local_storage_remove('projects');
			local_storage_remove('snaps');
		}
	});

	function handleAuth() {
		actor_assets_file_chunks.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'assets_file_chunks',
				identity: $auth_client.getIdentity()
			})
		}));

		actor_assets_img_staging.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'assets_img_staging',
				identity: $auth_client.getIdentity()
			})
		}));

		actor_username.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'username',
				identity: $auth_client.getIdentity()
			})
		}));

		actor_profile.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'profile',
				identity: $auth_client.getIdentity()
			})
		}));

		actor_project_main.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'project_main',
				identity: $auth_client.getIdentity()
			})
		}));

		actor_snap_main.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'snap_main',
				identity: $auth_client.getIdentity()
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
		modal_visible.update((options) => {
			return {
				...options,
				snap_creation: !options.snap_creation
			};
		});
	}
</script>

<span>
	{#if $actor_username.loggedIn}
		<div class="flex items-center">
			<Button label="Upload" primary={true} class="mr-4" on:click={openSnapCreationModal} />
			<ProfileAvatar />
		</div>
	{:else}
		<Button secondary={true} label="Sign In" on:click={login} class="mr-4" />
		<Button primary={true} label="Let's get started!" />
	{/if}
</span>

<style>
</style>
