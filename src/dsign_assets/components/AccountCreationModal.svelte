<script>
	import { profileManager } from '../store/profile_manager';
	import AccountCreation from 'dsign-components/components/AccountCreation.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';
	import { getErrorMessage } from '../lib/utils';

	let errorMessages = {
		UsernameInvalid: 'Use lower case letters with 20 characters or less',
		UsernameTaken: 'Username already taken'
	};

	let errorMessage = '';
	let hasError = false;
	let isCreatingAccount = false;

	async function handleAccountCreation(e) {
		try {
			hasError = false;
			errorMessage = '';
			isCreatingAccount = true;

			const response = await $profileManager.actor.create_profile(e.detail.username);

			errorMessage = getErrorMessage(response, errorMessages);
			isCreatingAccount = false;

			if (errorMessage.length > 1) {
				hasError = true;
			}
		} catch (error) {
			hasError = true;
			isCreatingAccount = false;
			errorMessage = 'Failed calling create profile';
		}
	}
</script>

<Modal>
	<AccountCreation on:click={handleAccountCreation} {errorMessage} {hasError} {isCreatingAccount} />
</Modal>

<style>
</style>
