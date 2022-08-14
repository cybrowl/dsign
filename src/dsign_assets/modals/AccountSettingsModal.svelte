<script>
	import AccountSettings from 'dsign-components/components/AccountSettings.svelte';
	import get from 'lodash/get.js';
	import Modal from 'dsign-components/components/Modal.svelte';

	import { createActor as create_actor_username, actor_username } from '../store/actor_username';
	import { createActor as create_actor_profile, actor_profile } from '../store/actor_profile';
	import {
		createActor as create_actor_profile_avatar_main,
		actor_profile_avatar_main
	} from '../store/actor_profile_avatar_main';

	import { auth_client } from '../store/client';
	import { isAccountSettingsModalVisible } from '../store/modal';
	import { local_storage_profile, local_storage_remove } from '../store/local_storage';

	async function handleAvatarChange(event) {
		let files = event.detail;

		const selectedFile = files[0];

		const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
		const avatar = {
			data: [...imageAsUnit8ArrayBuffer]
		};

		await $actor_profile_avatar_main.actor.save_image(avatar);
		let {
			ok: { profile }
		} = await $actor_profile.actor.get_profile();

		local_storage_profile.set({
			avatar_url: get(profile, 'avatar_url', '') + '&' + Math.floor(Math.random() * 100),
			username: get(profile, 'username', ''),
			website: ''
		});
	}

	function handleCloseModal() {
		isAccountSettingsModalVisible.update(
			(isAccountSettingsModalVisible) => !isAccountSettingsModalVisible
		);
	}

	async function handleLogOut() {
		await $auth_client.logout();

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

		actor_profile_avatar_main.update(() => ({
			loggedIn: false,
			actor: create_actor_profile_avatar_main({
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
