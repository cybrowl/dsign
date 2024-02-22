<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	import { AccountCreation, AccountCreationSuccess, Modal } from 'dsign-components';
	import { actor_username_registry } from '$stores_ref/actors';
	import { auth, init_auth } from '$stores_ref/auth_client';

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

	async function handleAccountCreation(event) {
		if (!$actor_username_registry.loggedIn) return;

		isCreatingAccount = true;
		try {
			const { ok: username, err: error } = await $actor_username_registry.actor.create_profile(
				event.detail.username
			);

			if (error) {
				let errorKey = Object.keys(error)[0];
				usernameInputError = usernameInputErrorMessages[errorKey] || 'An unexpected error occurred';
				throw new Error(usernameInputError); // Using throw to skip to catch block
			}

			createdAccount = true;
			setTimeout(() => {
				goto(`/${username}`);
			}, 2000);
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
			on:click={handleAccountCreation}
			errorMessage={usernameInputError}
			{hasError}
			{isCreatingAccount}
		/>
	{/if}
</Modal>

<style>
</style>
