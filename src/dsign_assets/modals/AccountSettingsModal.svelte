<script>
	import get from 'lodash/get.js';

	import AccountSettings from 'dsign-components/components/AccountSettings.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';

	// actors
	import {
		actor_assets_file_chunks,
		actor_assets_img_staging,
		actor_profile,
		actor_project_main,
		actor_snap_main,
		createActor
	} from '../store/actors';

	import { auth_client } from '../store/auth_client';
	import { modal_visible } from '../store/modal';
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

			let { ok: profile } = await $actor_profile.actor.get_profile();

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
		modal_visible.update((options) => {
			return {
				...options,
				account_settings: !options.account_settings
			};
		});
	}

	async function handleLogOut() {
		await $auth_client.logout();

		actor_assets_file_chunks.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'assets_file_chunks',
				identity: $auth_client.getIdentity()
			})
		}));

		actor_assets_img_staging.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'assets_img_staging',
				identity: $auth_client.getIdentity()
			})
		}));

		actor_profile.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'profile',
				identity: $auth_client.getIdentity()
			})
		}));

		actor_project_main.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'project_main',
				identity: $auth_client.getIdentity()
			})
		}));

		actor_snap_main.update(() => ({
			loggedIn: false,
			actor: createActor({
				actor_name: 'snap_main',
				identity: $auth_client.getIdentity()
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
	/>
</Modal>

<style>
</style>
