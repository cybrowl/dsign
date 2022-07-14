<script>
	import { onMount } from 'svelte';
	import AccountCreation from 'dsign-components/components/AccountCreation.svelte';
	import AccountCreationSuccess from 'dsign-components/components/AccountCreationSuccess.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';
	import { getErrorMessage } from '../lib/utils';

	import { actor_username } from '../store/actor_username';
	import { actor_snap_main } from '../store/actor_snap_main';

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
		await $actor_snap_main.actor.create_user_snap_storage();
	});

	async function handleAccountCreation(e) {
		try {
			hasError = false;
			errorMessage = '';
			isCreatingAccount = true;

			const response = await $actor_username.actor.create_username(e.detail.username);

			errorMessage = getErrorMessage(response, errorMessages);
			isCreatingAccount = false;

			if (errorMessage.length > 1) {
				hasError = true;
			}

			if (response.ok) {
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
