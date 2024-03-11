<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import environment from 'environment';
	import { get } from 'lodash';

	import { Avatar, Button, Icon } from 'dsign-components';

	import { actor_username_registry, actor_creator } from '$stores_ref/actors';
	import { auth_client, auth, init_auth } from '$stores_ref/auth_client';
	import { ls_my_profile } from '$stores_ref/local_storage';
	import modal_update from '$stores_ref/modal';

	const isProd = ['ic', 'staging'].includes(environment()['DFX_NETWORK']);

	onMount(() => {
		initialize_authentication_and_fetch_profile();
	});

	async function initialize_authentication_and_fetch_profile() {
		try {
			await init_auth();
			await fetch_and_set_profile();
		} catch (error) {
			console.error('Initialization or Profile Fetch Failed: ', error);
			goto('/');
		}
	}

	async function fetch_and_set_profile() {
		await auth.username_registry();

		if (!$actor_username_registry.loggedIn) return;

		const { ok: username_info, err: err_username } =
			await $actor_username_registry.actor.get_info();
		if (!username_info) return goto('/account_creation');

		await auth.creator(username_info.canister_id);

		if (!$actor_creator.loggedIn) return;

		const { ok: profile, err: err_profile } = await $actor_creator.actor.get_profile_by_username(
			username_info.username
		);

		if (profile) {
			ls_my_profile.set(profile);
		} else if (err_profile && err_profile['ProfileNotFound']) {
			goto('/account_creation');
		}
	}

	async function handle_auth() {
		try {
			await fetch_and_set_profile();
			goto(`/${get($ls_my_profile, 'username', '')}`);
		} catch (error) {
			console.error('Auth Handle Error: ', error);
			goto('/account_creation');
		}
	}

	function login() {
		const identityProviderUrl = isProd
			? 'https://identity.ic0.app/#authorize'
			: 'http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:8080/';
		$auth_client.login({
			identityProvider: identityProviderUrl,
			maxTimeToLive: BigInt(30 * 24 * 60 * 60 * 1000 * 1000 * 1000 * 1000),
			onSuccess: handle_auth
		});
	}

	async function navigate_to_profile() {
		goto(`/${get($ls_my_profile, 'username', '')}`);
	}

	async function open_settings_modal() {
		modal_update.change_visibility('account_settings');
	}
</script>

<span>
	{#if $actor_username_registry.loggedIn}
		<span class="flex gap-x-3 cursor-pointer">
			<Avatar
				avatar={get($ls_my_profile, 'avatar.url', '')}
				username={get($ls_my_profile, 'username', '')}
				on:click={navigate_to_profile}
			/>
			<Icon
				name="settings"
				size="2.75rem"
				class="cursor_pointer fill_dark_grey hover_smoky_grey responsive_icon"
				on:click={open_settings_modal}
				viewSize={{
					width: '44',
					height: '44'
				}}
			/>
		</span>
	{:else}
		<Button class="hover_lilalic_purple" primary={true} label="Login / Register" on:click={login} />
	{/if}
</span>

<style>
</style>
