<script>
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import environment from 'environment';
	import get from 'lodash/get.js';

	import Avatar from 'dsign-components/components/Avatar.svelte';
	import Button from 'dsign-components/components/Button.svelte';

	import { actor_profile } from '$stores_ref/actors';
	import { auth_client, auth_profile } from '$stores_ref/auth_client';
	import { local_storage_profile } from '$stores_ref/local_storage';
	import modal_update from '$stores_ref/modal';

	const env = environment();
	const isProd = env['DFX_NETWORK'] === 'ic' || false;

	onMount(async () => {
		await auth_profile();

		if ($actor_profile.loggedIn) {
			try {
				let { ok: profile, err: err_profile } = await $actor_profile.actor.get_profile();

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
				location.replace('/');
			}
		}
	});

	async function handleAuth() {
		await auth_profile();

		try {
			if ($actor_profile.loggedIn) {
				let { ok: profile, err: err_profile } = await $actor_profile.actor.get_profile();

				if (profile) {
					window.location.reload();
				}

				if (err_profile) {
					if (err_profile['ProfileNotFound'] === true) {
						goto('/account_creation');
					}
				}
			}
		} catch (error) {}
	}

	function login() {
		$auth_client.login({
			identityProvider: isProd
				? 'https://identity.icp0.io/#authorize'
				: 'http://localhost:8080/?canisterId=rwlgt-iiaaa-aaaaa-aaaaa-cai',
			onSuccess: handleAuth
		});
	}

	async function openSettingsModal() {
		modal_update.change_visibility('account_settings');
	}
</script>

<span>
	{#if $actor_profile.loggedIn}
		<div class="flex items-center">
			<Avatar
				avatar={$local_storage_profile.avatar_url}
				username={$local_storage_profile.username}
				on:click={openSettingsModal}
			/>
		</div>
	{:else}
		<Button primary={true} label="Connect" on:click={login} />
	{/if}
</span>

<style>
</style>
