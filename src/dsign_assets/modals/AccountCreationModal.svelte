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

	let username_input_err_msgs = {
		UsernameInvalid: 'Use lower case letters and numbers only, 2 - 20 characters in length',
		UsernameTaken: 'Username already taken'
	};

	let createdAccount = false;
	let username_input_err = '';
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
			username_input_err = '';
			isCreatingAccount = true;

			let { ok: username, err: err_create_username } = await $actor_username.actor.create_username(
				e.detail.username
			);

			if (err_create_username) {
				hasError = true;
				isCreatingAccount = false;
				let err_create_username_key = Object.keys(err_create_username)[0];
				username_input_err = username_input_err_msgs[err_create_username_key];

				return;
			}

			let { ok: profile, err: err_create_profile } = await $actor_profile.actor.create_profile();

			if (err_create_profile) {
				isCreatingAccount = false;

				// profile err
				// let err_create_profile_key = Object.keys(err_create_profile)[0];
				// let notification_err = errorMessages[err_create_profile_key];

				//TODO: add notification err
				return;
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

			//TODO: add notification err
			username_input_err = 'Failed calling create profile';
		}
	}
</script>

<Modal isModalLocked={isCreatingAccount}>
	{#if createdAccount}
		{#if isVisible}
			<AccountCreationSuccess />
		{/if}
	{:else}
		<AccountCreation
			on:click={handleAccountCreation}
			errorMessage={username_input_err}
			{hasError}
			{isCreatingAccount}
		/>
	{/if}
</Modal>

<style>
</style>
