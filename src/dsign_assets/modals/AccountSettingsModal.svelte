<script>
	import { onMount } from 'svelte';
	import get from 'lodash/get.js';

	import { AccountSettings, Modal } from 'dsign-components';

	import { actor_assets_img_staging, actor_profile } from '$stores_ref/actors';
	import {
		auth_assets_img_staging,
		auth_client,
		auth_logout_all,
		auth_profile
	} from '$stores_ref/auth_client';
	import { local_storage_profile, local_storage_remove_all } from '$stores_ref/local_storage';
	import modal_update from '$stores_ref/modal';

	onMount(async () => {
		await Promise.all([auth_profile(), auth_assets_img_staging()]);
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

		if ($actor_assets_img_staging.loggedIn && $actor_profile.loggedIn) {
			try {
				// commit img asset to staging
				let img_asset_id = await $actor_assets_img_staging.actor.create_asset(create_asset_args);

				// update profile avatar
				const { ok: avatar_url, err: err_update_avatar } =
					await $actor_profile.actor.update_profile_avatar([img_asset_id]);

				if (err_update_avatar) {
					//TODO: add notification
				}

				let { ok: profile } = await $actor_profile.actor.get_profile();

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
