<script>
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';
	import { createActor as createActorProfile } from '$ICprofile';
	import { createActor as createActorProfileManager } from '$ICprofile_manager';
	import { auth as authProfile } from '../store/profile';
	import { auth as authProfileManager } from '../store/profile_manager';

	let client;

	let profileIdentity = $authProfile.actor.get_canister_caller_principal();
	let profileManagerIdentity = $authProfileManager.actor.get_canister_caller_principal();

	onMount(async () => {
		client = await AuthClient.create();

		if (await client.isAuthenticated()) {
			handleAuth();
		}
	});

	function handleAuth() {
		authProfile.update(() => ({
			loggedIn: true,
			actor: createActorProfile({
				agentOptions: {
					identity: client.getIdentity()
				}
			})
		}));

		authProfileManager.update(() => ({
			loggedIn: true,
			actor: createActorProfileManager({
				agentOptions: {
					identity: client.getIdentity()
				}
			})
		}));

		profileIdentity = $authProfile.actor.get_canister_caller_principal();
		profileManagerIdentity = $authProfileManager.actor.get_canister_caller_principal();
	}

	function login() {
		client.login({
			identityProvider: 'https://identity.ic0.app/#authorize',
			onSuccess: handleAuth
		});
	}

	async function logout() {
		await client.logout();

		authProfile.update(() => ({
			loggedIn: false,
			actor: createActorProfile({
				agentOptions: {
					identity: client.getIdentity()
				}
			})
		}));

		authProfileManager.update(() => ({
			loggedIn: false,
			actor: createActorProfileManager({
				agentOptions: {
					identity: client.getIdentity()
				}
			})
		}));

		profileIdentity = $authProfile.actor.get_canister_caller_principal();
		profileManagerIdentity = $authProfileManager.actor.get_canister_caller_principal();
	}
</script>

<div class="container">
	{#if $authProfile.loggedIn}
		<div>
			<button on:click={logout}>Log out</button>
		</div>
	{:else}
		<button
			class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
			on:click={login}>Login</button
		>
	{/if}

	<div class="principal-info-profileIdentity">
		{#await profileIdentity}
			Querying caller identity...
		{:then principal}
			profileIdentity
			<code>{principal}</code>
		{/await}
	</div>

	{#if $authProfileManager.loggedIn}
		<div>
			<button on:click={logout}> profileManagerIdentity Log out</button>
		</div>
	{:else}
		<button
			class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
			on:click={login}>Login</button
		>
	{/if}

	<div class="principal-info-profileManagerIdentity">
		{#await profileManagerIdentity}
			Querying caller identity...
		{:then principal}
			profileManagerIdentity
			<code>{principal}</code>
		{/await}
	</div>
</div>

<style>
	.container {
		margin: 64px 0;
	}
</style>
