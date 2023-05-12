<script>
	import { onMount } from 'svelte';

	import { AccountCreation, AccountCreationSuccess, Modal } from 'dsign-components-v2';

	import {
		actor_favorite_main,
		actor_profile,
		actor_project_main,
		actor_snap_main
	} from '$stores_ref/actors';
	import { auth_snap_main, auth_project_main, auth_favorite_main } from '$stores_ref/auth_client';

	let username_input_err_msgs = {
		UsernameInvalid: 'Use lower case letters and numbers only, 2 - 20 characters in length',
		UsernameTaken: 'Username already taken'
	};

	let createdAccount = false;
	let hasError = false;
	let isCreatingAccount = false;
	let username_input_err = '';

	onMount(async () => {
		await Promise.all([auth_project_main(), auth_snap_main(), auth_favorite_main()]);
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

					if (
						$actor_favorite_main.loggedIn &&
						$actor_project_main.loggedIn &&
						$actor_snap_main.loggedIn
					) {
						await Promise.all([
							$actor_favorite_main.actor.create_user_favorite_storage(),
							$actor_project_main.actor.create_user_project_storage(),
							$actor_snap_main.actor.create_user_snap_storage()
						]);
					}

					setTimeout(function () {
						location.replace(`/${username}`);
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
