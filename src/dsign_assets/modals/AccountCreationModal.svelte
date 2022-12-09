<script>
	import { onMount } from 'svelte';

	import AccountCreation from 'dsign-components/components/AccountCreation.svelte';
	import AccountCreationSuccess from 'dsign-components/components/AccountCreationSuccess.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';

	// actors
	import {
		actor_favorite_main,
		actor_profile,
		actor_project_main,
		actor_snap_main
	} from '$stores_ref/actors';

	let username_input_err_msgs = {
		UsernameInvalid: 'Use lower case letters and numbers only, 2 - 20 characters in length',
		UsernameTaken: 'Username already taken'
	};

	let createdAccount = false;
	let hasError = false;
	let isCreatingAccount = false;
	let username_input_err = '';

	onMount(async () => {
		if ($actor_favorite_main.loggedIn) {
			await $actor_favorite_main.actor.create_user_favorite_storage();
		}

		if ($actor_project_main.loggedIn) {
			await $actor_project_main.actor.create_user_project_storage();
		}

		if ($actor_snap_main.loggedIn) {
			await $actor_snap_main.actor.create_user_snap_storage();
		}
	});

	async function handleAccountCreation(e) {
		if ($actor_profile.loggedIn) {
			try {
				hasError = false;
				username_input_err = '';
				isCreatingAccount = true;

				let { ok: username, err: err_create_username } = await $actor_profile.actor.create_username(
					e.detail.username
				);

				if (err_create_username) {
					hasError = true;
					isCreatingAccount = false;
					let err_create_username_key = Object.keys(err_create_username)[0];
					username_input_err = username_input_err_msgs[err_create_username_key];

					return;
				}

				if (username) {
					createdAccount = true;

					setTimeout(function () {
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
	}
</script>

<Modal isModalLocked={true}>
	{#if createdAccount}
		<AccountCreationSuccess />
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
