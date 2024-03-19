<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	import { AccountCreation, AccountCreationSuccess, Modal } from 'dsign-components';
	import { actor_username_registry, actor_creator } from '$stores_ref/actors';
	import { auth, init_auth } from '$stores_ref/auth_client';
	import { ls_my_profile } from '$stores_ref/local_storage';

	const usernameInputErrorMessages = {
		CallerAnonymous: 'Something wrong with identity, Anon!',
		UsernameInvalid: 'Use lower case letters and numbers only, 2 - 20 characters in length',
		UsernameTaken: 'Username already taken'
	};

	let createdAccount = false;
	let hasError = false;
	let isCreatingAccount = false;
	let usernameInputError = '';

	onMount(() => {
		initializeAuthentication();
	});

	async function initializeAuthentication() {
		try {
			await init_auth();
			await auth.username_registry();

			const { ok: usernameInfo } = await $actor_username_registry.actor.get_info();
			if (usernameInfo?.username) {
				goto(`/${usernameInfo.username}`);
			}
		} catch (error) {
			console.error('Error during authentication initialization: ', error);
			// Consider handling this error or notifying the user
		}
	}

	async function create_account(event) {
		if (!$actor_username_registry.loggedIn) return;

		isCreatingAccount = true;

		try {
			await auth.username_registry();
			const { ok: username, err: error } = await $actor_username_registry.actor.create_profile(
				event.detail.username
			);

			if (error) {
				let errorKey = Object.keys(error)[0];
				usernameInputError = usernameInputErrorMessages[errorKey] || 'An unexpected error occurred';
				throw new Error(usernameInputError);
			}

			const { ok: username_info } = await $actor_username_registry.actor.get_info();
			await auth.creator(username_info.canister_id);
			if ($actor_creator.loggedIn) {
				const { ok: profile, err: err_profile } =
					await $actor_creator.actor.get_profile_by_username(username);

				ls_my_profile.set(profile);

				createdAccount = true;
				setTimeout(() => {
					goto(`/${username}`);
				}, 2000);
			}
		} catch (error) {
			console.error('Account creation error: ', error.message);
			hasError = true;
			usernameInputError = error.message || 'Failed calling create profile';
		} finally {
			isCreatingAccount = false;
		}
	}
</script>

<Modal isModalLocked={true} modalHeaderVisible={false}>
	{#if createdAccount}
		<AccountCreationSuccess />
	{:else}
		<AccountCreation
			on:click={create_account}
			errorMessage={usernameInputError}
			{hasError}
			{isCreatingAccount}
		/>
	{/if}
</Modal>

<style>
</style>
