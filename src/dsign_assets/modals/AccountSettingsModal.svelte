<script>
	import AccountSettings from 'dsign-components/components/AccountSettings.svelte';
	import get from 'lodash/get.js';
	import Modal from 'dsign-components/components/Modal.svelte';

	import {
		createActor as create_actor_assets_file_chunks,
		actor_assets_file_chunks
	} from '../store/actor_assets_file_chunks';
	import {
		createActor as create_actor_assets_img_staging,
		actor_assets_img_staging
	} from '../store/actor_assets_img_staging';
	import { createActor as create_actor_username, actor_username } from '../store/actor_username';
	import { createActor as create_actor_profile, actor_profile } from '../store/actor_profile';
	import {
		createActor as create_actor_project_main,
		actor_project_main
	} from '../store/actor_project_main';
	import { createActor as create_actor_snap_main, actor_snap_main } from '../store/actor_snap_main';

	import { auth_client } from '../store/auth_client';
	import { isAccountSettingsModalVisible } from '../store/modal';
	import { local_storage_profile, local_storage_remove } from '../store/local_storage';

	async function handleAvatarChange(event) {
		let files = event.detail;

		const selectedFile = files[0];

		const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
		const create_asset_args = {
			data: [...imageAsUnit8ArrayBuffer],
			file_format: selectedFile.type
		};

		try {
			let img_asset_id = await $actor_assets_img_staging.actor.create_asset(create_asset_args);
			await $actor_profile.actor.update_profile_avatar([img_asset_id]);

			let {
				ok: { profile }
			} = await $actor_profile.actor.get_profile();

			local_storage_profile.set({
				avatar_url: get(profile, 'avatar.url', '') + '&' + Math.floor(Math.random() * 100),
				username: get(profile, 'username', ''),
				website: ''
			});
		} catch (error) {
			console.log('error', error);
		}
	}

	function handleCloseModal() {
		isAccountSettingsModalVisible.update(
			(isAccountSettingsModalVisible) => !isAccountSettingsModalVisible
		);
	}

	async function handleLogOut() {
		await $auth_client.logout();

		actor_assets_file_chunks.update(() => ({
			loggedIn: false,
			actor: create_actor_assets_file_chunks({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		actor_assets_img_staging.update(() => ({
			loggedIn: false,
			actor: create_actor_assets_img_staging({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		actor_username.update(() => ({
			loggedIn: false,
			actor: create_actor_username({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		actor_profile.update(() => ({
			loggedIn: false,
			actor: create_actor_profile({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		actor_project_main.update(() => ({
			loggedIn: false,
			actor: create_actor_project_main({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		actor_snap_main.update(() => ({
			loggedIn: false,
			actor: create_actor_snap_main({
				agentOptions: {
					identity: $auth_client.getIdentity()
				}
			})
		}));

		local_storage_remove('profile');

		handleCloseModal();

		window.location.href = '/';
	}
</script>

<Modal on:closeModal={handleCloseModal}>
	<AccountSettings
		avatar={$local_storage_profile.avatar_url}
		username={$local_storage_profile.username}
		on:avatarChange={handleAvatarChange}
		on:clickLogOut={handleLogOut}
		triggerInputEvent={true}
	/>
</Modal>

<style>
</style>
