<script>
	import { onMount } from 'svelte';
	import get from 'lodash/get.js';

	import { AccountSettings, Modal } from 'dsign-components';

	import {
		actor_creator,
		actor_file_scaling_manager,
		actor_file_storage,
		actor_username_registry
	} from '$stores_ref/actors';
	import { auth, auth_client, auth_logout_all } from '$stores_ref/auth_client';
	import { local_storage_profile, local_storage_remove_all } from '$stores_ref/local_storage';
	import modal_update from '$stores_ref/modal';

	import { FileStorage } from '$utils/file_storage';

	onMount(async () => {
		await Promise.all([]);
	});

	function handleCloseModal() {
		modal_update.change_visibility('account_settings');
	}

	async function handleAvatarChange(event) {
		let file = event.detail;
		const file_unit8 = new Uint8Array(await file.arrayBuffer());

		//TODO: rename to say something about storage canister id and about it being empty
		const storage_canister_id_alloc =
			await $actor_file_scaling_manager.actor.get_current_canister_id();

		await auth.creator(profile.canister_id);
		await auth.file_storage(storage_canister_id_alloc);

		const file_storage = new FileStorage($actor_file_storage.actor);

		const { ok: file_public } = await file_storage.store(file_unit8, {
			filename: file.name,
			content_type: file.type
		});

		const { ok: banner_url, err: err_banner_update } =
			await $actor_creator.actor.update_profile_banner({
				id: file_public.id,
				canister_id: file_public.canister_id,
				url: file_public.url
			});

		local_storage_profile.update((currentValues) => {
			return {
				...currentValues,
				banner_url: banner_url
			};
		});
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
