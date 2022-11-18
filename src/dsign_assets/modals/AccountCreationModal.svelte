<script>
	import { onMount } from 'svelte';

	import AccountCreation from 'dsign-components/components/AccountCreation.svelte';
	import AccountCreationSuccess from 'dsign-components/components/AccountCreationSuccess.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';

	// actors
	import {
		actor_profile,
		actor_project_main,
		actor_snap_main,
		actor_username
	} from '../store/actors';

	// utils
	import { getErrorMessage } from '../lib/utils';

	let errorMessages = {
		UsernameInvalid: 'Use lower case letters and numbers only, 2 - 20 characters in length',
		UsernameTaken: 'Username already taken'
	};

	let createdAccount = false;
	let errorMessage = '';
	let hasError = false;
	let isCreatingAccount = false;
	let isVisible = true;

	onMount(async () => {
		await $actor_project_main.actor.create_user_project_storage();
		await $actor_snap_main.actor.create_user_snap_storage();
	});

	async function handleAccountCreation(e) {
		try {
			hasError = false;
			errorMessage = '';
			isCreatingAccount = true;

			let { ok: username, err: err_username } = await $actor_username.actor.create_username(
				e.detail.username
			);
			let { ok: profile, err: err_profile } = await $actor_profile.actor.create_profile();

			isCreatingAccount = false;

			if (err_profile || err_username) {
				console.log('err_profile', err_profile);
				console.log('err_username', err_username);
				// errorMessage = getErrorMessage(response, errorMessages);
				// isCreatingAccount = false;
				// if (errorMessage.length > 1) {
				// 	hasError = true;
				// }
			}

			if (username && profile) {
				createdAccount = true;

				setTimeout(function () {
					isVisible = false;
					location.replace('/projects');
				}, 2000);
			}
		} catch (error) {
			hasError = true;
			isCreatingAccount = false;
			errorMessage = 'Failed calling create profile';
		}
	}
</script>

<Modal modalHeaderVisible={!createdAccount}>
	{#if createdAccount}
		{#if isVisible}
			<AccountCreationSuccess />
		{/if}
	{:else}
		<AccountCreation
			on:click={handleAccountCreation}
			{errorMessage}
			{hasError}
			{isCreatingAccount}
		/>
	{/if}
</Modal>

<style>
</style>
