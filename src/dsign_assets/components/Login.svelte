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
		actor_explore,
		actor_profile,
		actor_project_main,
		actor_snap_main,
		createActor
	} from '../store/actors';

	import { auth_client } from '../store/auth_client';
	import { local_storage_remove } from '../store/local_storage';

	const env = environment();
	const isProd = env['DFX_NETWORK'] === 'ic' || false;
	let authClient;

	onMount(async () => {
		authClient = await AuthClient.create();
		let isAuthenticated = await authClient.isAuthenticated();

		auth_client.set(authClient);

		if (isAuthenticated) {
			handleAuth();
		} else {
			handleLogout();
		}
	});

	function handleLogout() {
		actor_assets_file_chunks.update((args) => ({
			...args,
			loggedIn: false
		}));

		actor_assets_img_staging.update((args) => ({
			...args,
			loggedIn: false
		}));

		actor_explore.update((args) => ({
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

	function handleAuth() {
		actor_assets_file_chunks.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'assets_file_chunks',
				identity: authClient.getIdentity()
			})
		}));

		actor_assets_img_staging.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'assets_img_staging',
				identity: authClient.getIdentity()
			})
		}));

		actor_explore.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'explore',
				identity: authClient.getIdentity()
			})
		}));

		actor_profile.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'profile',
				identity: authClient.getIdentity()
			})
		}));

		actor_project_main.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'project_main',
				identity: authClient.getIdentity()
			})
		}));

		actor_snap_main.update(() => ({
			loggedIn: true,
			actor: createActor({
				actor_name: 'snap_main',
				identity: authClient.getIdentity()
			})
		}));
	}

	function login() {
		authClient.login({
			identityProvider: isProd
				? 'https://identity.ic0.app/#authorize'
				: 'http://localhost:8080/?canisterId=rwlgt-iiaaa-aaaaa-aaaaa-cai',
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
	{#if $actor_profile.loggedIn}
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
