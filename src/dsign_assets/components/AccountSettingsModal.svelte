<script>
	import { client } from '../store/client';
	import { createActor, profileManager } from '../store/profile_manager';
	import { isAccountSettingsModalVisible } from '../store/modal';
	import { profileStorage } from '../store/local_storage';
	import { removeFromStorage } from '../store/local_storage';
	import get from 'lodash/get.js';
	import Modal from 'dsign-components/components/Modal.svelte';
	import AccountSettings from 'dsign-components/components/AccountSettings.svelte';

	async function handleAvatarChange(event) {
		let files = event.detail;

		const selectedFile = files[0];

		const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
		const avatar = {
			content: [...imageAsUnit8ArrayBuffer]
		};

		await $profileManager.actor.set_avatar(avatar);
		let { ok: profile } = await $profileManager.actor.get_profile();

		profileStorage.set({
			avatar: get(profile, 'avatar', '') + '&' + Math.floor(Math.random() * 100),
			username: get(profile, 'username', ''),
			website: ''
		});
	}

	function handleCloseModal() {
		isAccountSettingsModalVisible.update((isAccountSettingsModalVisible) => !isAccountSettingsModalVisible);
	}

	async function handleLogOut() {
		await $client.logout();

		profileManager.update(() => ({
			loggedIn: false,
			actor: createActor({
				agentOptions: {
					identity: $client.getIdentity()
				}
			})
		}));

		removeFromStorage('profile');

		handleCloseModal();
	}
</script>

<Modal centered={false} on:closeModal={handleCloseModal}>
	<AccountSettings
		avatar={$profileStorage.avatar}
		username={$profileStorage.username}
		on:avatarChange={handleAvatarChange}
		on:clickLogOut={handleLogOut}
		triggerInputEvent={true}
	/>
</Modal>

<style>
</style>
