<script>
	import { onMount } from 'svelte';
	import get from 'lodash/get.js';

	import { AccountSettings, Modal } from 'dsign-components';

	import {} from '$stores_ref/actors';
	import { auth, auth_client, auth_logout_all } from '$stores_ref/auth_client';
	import { local_storage_profile, local_storage_remove_all } from '$stores_ref/local_storage';
	import modal_update from '$stores_ref/modal';

	onMount(async () => {
		await Promise.all([]);
	});

	function handleCloseModal() {
		modal_update.change_visibility('account_settings');
	}

	async function handleAvatarChange(event) {
		let files = event.detail;

		const selectedFile = files[0];

		const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
		const create_asset_args = {
			data: [...imageAsUnit8ArrayBuffer],
			file_format: selectedFile.type
		};

		const creator_logged_in = false;

		if (creator_logged_in) {
			try {
				//TODO: store image
				//TODO: update profile avatar

				if (err_update_avatar) {
					//TODO: add notification
				}

				//TODO: get profile

				const randomNumber = Math.floor(Math.random() * 1000);
				local_storage_profile.set({
					avatar_url: get(profile, 'avatar.url', '') + '&' + randomNumber,
					banner_url: get(profile, 'banner.url', '') || '/default_profile_banner.png',
					username: get(profile, 'username', ''),
					website: ''
				});
			} catch (error) {
				console.log('error', error);
			}
		}
	}

	async function handleLogOut() {
		await $auth_client.logout();

		await auth_logout_all();

		local_storage_remove_all();

		location.replace('/');
	}
</script>

<Modal on:closeModal={handleCloseModal}>
	<AccountSettings
		avatar={$local_storage_profile.avatar_url}
		username={$local_storage_profile.username}
		on:avatarChange={handleAvatarChange}
		on:clickLogOut={handleLogOut}
	/>
</Modal>

<style>
</style>
