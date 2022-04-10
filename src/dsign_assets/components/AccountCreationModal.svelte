<script>
	import { getErrorMessage } from '../lib/utils';
	import { accountSettings } from '../store/account_settings';
	import AccountCreation from 'dsign-components/components/AccountCreation.svelte';
	import AccountCreationSuccess from 'dsign-components/components/AccountCreationSuccess.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';

	let errorMessages = {
		UsernameInvalid: 'Use lower case letters and numbers only, 2 - 20 characters in length',
		UsernameTaken: 'Username already taken'
	};

	let createdAccount = false;
	let errorMessage = '';
	let hasError = false;
	let isCreatingAccount = false;
	let isVisible = true;

	async function handleAccountCreation(e) {
		try {
			hasError = false;
			errorMessage = '';
			isCreatingAccount = true;

			const response = await $accountSettings.actor.create_profile(e.detail.username);

			errorMessage = getErrorMessage(response, errorMessages);
			isCreatingAccount = false;

			if (errorMessage.length > 1) {
				hasError = true;
			}

			if (response.ok) {
				createdAccount = true;

				setTimeout(function () {
					isVisible = false;
					location.replace("/projects");
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
