<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import environment from 'environment';
	import get from 'lodash/get.js';

	import Avatar from 'dsign-components/components/Avatar.svelte';
	import Button from 'dsign-components/components/Button.svelte';

	import { actor_profile } from '$stores_ref/actors';
	import { auth_client } from '$stores_ref/auth_client';
	import { local_storage_profile, local_storage_remove } from '$stores_ref/local_storage';
	import { modal_visible } from '$stores_ref/modal';
	import modal_update from '$stores_ref/modal_update';

	const env = environment();
	const isProd = env['DFX_NETWORK'] === 'ic' || false;

	onMount(async () => {
		console.log('Login: onMount: actor_profile: ', $actor_profile.loggedIn);

		if ($actor_profile.loggedIn) {
			try {
				let { ok: profile, err: err_profile } = await $actor_profile.actor.get_profile();

				console.log('profile: ', profile);
				console.log('err_profile: ', err_profile);
				if (profile) {
					local_storage_profile.set({
						avatar_url: get(profile, 'avatar.url', ''),
						username: get(profile, 'username', '')
					});
				}

				if (err_profile) {
					if (err_profile['ProfileNotFound'] === true) {
						goto('/account_creation');
					}
				}
			} catch (error) {
				// goto('/');
			}
		}
	});

	function handleAuth() {
		location.replace('/');
	}

	function login() {
		$auth_client.login({
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

	async function openSettingsModal() {
		modal_update.change_visibility('account_settings');
	}
</script>

<span>
	{#if $actor_profile.loggedIn}
		<div class="flex items-center">
			<Button label="Upload" primary={true} class="mr-4" on:click={openSnapCreationModal} />
			<Avatar
				avatar={$local_storage_profile.avatar_url}
				username={$local_storage_profile.username}
				on:click={openSettingsModal}
			/>
		</div>
	{:else}
		<Button secondary={true} label="Sign In" on:click={login} class="mr-4" />
		<Button primary={true} label="Let's get started!" on:click={login} />
	{/if}
</span>

<style>
</style>
