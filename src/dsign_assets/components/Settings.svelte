<script>
	import { client } from '../store/client';
	import { createActor, profileManager } from '../store/profile_manager';
	import { isSettingsActive } from '../store/modal';
	import { profileStorage } from '../store/local_storage';
	import { removeFromStorage } from '../store/local_storage';
	import Modal from 'dsign-components/components/Modal.svelte';
	import Settings from 'dsign-components/components/Settings.svelte';

	// let hasAvatar = $profileStorage.avatar.length > 3 || false;
	// let profilePromise = $profileManager.actor.get_profile();
	let username = $profileStorage.username;
	let count = 0;

	async function handleAvatarChange(event) {
		console.log('event: ', event);

		let files = event.detail;

		const selectedFile = files[0];

		const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
		const avatar = {
			content: [...imageAsUnit8ArrayBuffer]
		};

		await $profileManager.actor.set_avatar(avatar);
		let { ok: profile } = await $profileManager.actor.get_profile();

		count++;

		profileStorage.set({
			avatar: _.get(profile, 'avatar', '') + '&' + count,
			username: _.get(profile, 'username', ''),
			website: ''
		});
	}

	function handleCloseModal() {
		isSettingsActive.update((isSettingsActive) => !isSettingsActive);
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
	<Settings
		{username}
		on:clickLogOut={handleLogOut}
		on:avatarChange={handleAvatarChange}
		triggerInputEvent={true}
	/>
</Modal>

<style>
</style>
