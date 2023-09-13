<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import environment from 'environment';
	import { get } from 'lodash';

	import { Avatar, Button, Icon } from 'dsign-components';

	import { actor_profile } from '$stores_ref/actors';
	import { auth_client, auth, init_auth } from '$stores_ref/auth_client';
	import { local_storage_profile } from '$stores_ref/local_storage';
	import modal_update from '$stores_ref/modal';

	const env = environment();
	let isProd = false;

	if (env['DFX_NETWORK'] === 'ic' || env['DFX_NETWORK'] === 'staging') {
		isProd = true;
	}

	onMount(async () => {
		await init_auth();

		await auth.profile();

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
		await auth.profile();

		try {
			if ($actor_profile.loggedIn) {
				let { ok: profile, err: err_profile } = await $actor_profile.actor.get_profile();

				if (profile) {
					local_storage_profile.set({
						avatar_url: get(profile, 'avatar.url', ''),
						username: get(profile, 'username', '')
					});

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
				? 'https://identity.ic0.app/#authorize'
				: 'http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:8080/',
			maxTimeToLive: BigInt(30 * 24 * 60 * 60 * 1000 * 1000 * 1000 * 1000),
			onSuccess: handleAuth
		});
	}

	async function navigateToProfile() {
		goto(`/${$local_storage_profile.username}`);
	}

	async function openSettingsModal() {
		modal_update.change_visibility('account_settings');
	}
</script>

<span>
	{#if $actor_profile.loggedIn}
		<span class="flex gap-x-3 cursor-pointer">
			<Avatar
				avatar={$local_storage_profile.avatar_url}
				username={$local_storage_profile.username}
				on:click={navigateToProfile}
			/>
			<Icon
				name="settings"
				size="2.75rem"
				class="cursor_pointer fill_dark_grey hover_smoky_grey responsive_icon"
				on:click={openSettingsModal}
				viewSize={{
					width: '44',
					height: '44'
				}}
			/>
		</span>
	{:else}
		<Button class="hover_lilalic_purple" primary={true} label="Get Started" on:click={login} />
	{/if}
</span>

<style>
</style>
