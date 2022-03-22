<script>
	import { profileManager } from '../store/profile_manager';
	import Modal from 'dsign-components/components/Modal.svelte';
	import Settings from 'dsign-components/components/Settings.svelte';
	import { profileStorage } from '../store/local_storage';
	import { isSettingsActive } from '../store/modal';

	let hasAvatar = $profileStorage.avatar.length > 3 || false;
	let profilePromise = $profileManager.actor.get_profile();
	let username = $profileStorage.username;
	let files;
	let count = 0;

	async function handleAvatarChange() {
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
		isSettingsActive.update((isSettingsActive) => !isSettingsActive)
	}
</script>

<!-- <input type="file" bind:files on:change={handleAvatarChange} /> -->

<Modal
	centered={false}
	on:closeModal={handleCloseModal}
>
	<Settings on:clickAvatar={handleAvatarChange} {username} />
</Modal>

<style>
</style>
