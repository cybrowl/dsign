<script>
	import { profileManager } from '../store/profile_manager';
	import CreateUsername from 'dsign-components/components/CreateUsername.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';
	import { getErrorMessage } from '../lib/utils';

	let errorMessage = '';
	let errorMessages = {
		UsernameInvalid: 'Use lower case letters with 20 characters or less',
		UsernameTaken: 'Username already taken'
	};
	let isCreatingAccount = false;
	let hasError = false;

	async function handleCreateProfile(e) {
		isCreatingAccount = true;

		try {
			const response = await $profileManager.actor.create_profile(e.detail.username);

			isCreatingAccount = false;

			console.log("response: ", response);
			errorMessage = getErrorMessage(response, errorMessages);

			if (errorMessage.length > 1) {
				hasError = true;
			}
		} catch (error) {
			hasError = true;
			errorMessage = 'Failed calling create profile';
		}
	}
</script>

<Modal>
	<CreateUsername on:click={handleCreateProfile} {isCreatingAccount} {hasError} {errorMessage} />
</Modal>

<style>
</style>
