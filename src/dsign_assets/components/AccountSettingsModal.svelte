<script>
	import AccountSettings from 'dsign-components/components/AccountSettings.svelte';
	import get from 'lodash/get.js';
	import Modal from 'dsign-components/components/Modal.svelte';

	import { createActor as create_actor_username,  actor_username} from '../store/actor_username';
	import { createActor as create_actor_profile,  actor_profile} from '../store/actor_profile';

	import { client } from '../store/client';
	import { isAccountSettingsModalVisible } from '../store/modal';
	import { local_storage_profile } from '../store/local_storage';
	import { local_storage_remove } from '../store/local_storage';

	async function handleAvatarChange(event) {
		let files = event.detail;

		const selectedFile = files[0];

		const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
		const avatar = {
			content: [...imageAsUnit8ArrayBuffer]
		};

		// await $actor_username.actor.set_avatar(avatar);
		let { ok: { profile } } = await $actor_username.actor.get_profile();

		local_storage_profile.set({
			avatar_url: get(profile, 'avatar_url', '') + '&' + Math.floor(Math.random() * 100),
			username: get(profile, 'username', ''),
			website: ''
		});
	}

	function handleCloseModal() {
		isAccountSettingsModalVisible.update((isAccountSettingsModalVisible) => !isAccountSettingsModalVisible);
	}

	async function handleLogOut() {
		await $client.logout();

		actor_username.update(() => ({
			loggedIn: false,
			actor: create_actor_username({
				agentOptions: {
					identity: $client.getIdentity()
				}
			})
		}));

		actor_profile.update(() => ({
			loggedIn: false,
			actor: create_actor_profile({
				agentOptions: {
					identity: $client.getIdentity()
				}
			})
		}));

		local_storage_remove('profile');

		handleCloseModal();
	}
</script>

<Modal centered={false} on:closeModal={handleCloseModal}>
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
