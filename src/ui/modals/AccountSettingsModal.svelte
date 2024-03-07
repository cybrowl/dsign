<script>
	import { onMount } from 'svelte';
	import get from 'lodash/get.js';

	import { AccountSettings, Modal } from 'dsign-components';

	import {
		actor_creator,
		actor_file_scaling_manager,
		actor_file_storage
	} from '$stores_ref/actors';
	import { auth, auth_client, auth_logout_all } from '$stores_ref/auth_client';
	import { ls_my_profile, local_storage_remove_all } from '$stores_ref/local_storage';
	import modal_update from '$stores_ref/modal';

	import { FileStorage } from '$utils/file_storage';

	onMount(async () => {
		await Promise.all([]);
	});

	// ------------------------- Modals -------------------------
	function modal_close_account_settings() {
		modal_update.change_visibility('account_settings');
	}

	// ------------------------- API -------------------------
	async function update_profile_avatar(event) {
		let file = event.detail;
		const file_unit8 = new Uint8Array(await file.arrayBuffer());

		//TODO: rename to say something about storage canister id and about it being empty
		const storage_canister_id_alloc =
			await $actor_file_scaling_manager.actor.get_current_canister_id();

		await auth.creator(get($ls_my_profile, 'canister_id', ''));
		await auth.file_storage(storage_canister_id_alloc);

		const file_storage = new FileStorage($actor_file_storage.actor);

		const { ok: file_public } = await file_storage.store(file_unit8, {
			filename: file.name,
			content_type: file.type
		});

		const { ok: url, err: err_banner_update } = await $actor_creator.actor.update_profile_avatar({
			id: file_public.id,
			canister_id: file_public.canister_id,
			url: file_public.url
		});

		ls_my_profile.update((values) => {
			return {
				...values,
				avatar: {
					id: file_public.id,
					canister_id: file_public.canister_id,
					url: url
				}
			};
		});
	}

	// ------------------------- Logout -------------------------
	async function logout_auth() {
		await $auth_client.logout();

		await auth_logout_all();

		local_storage_remove_all();

		location.replace('/');
	}
</script>

<Modal on:closeModal={modal_close_account_settings}>
	<AccountSettings
		avatar={get($ls_my_profile, 'avatar.url', '')}
		username={get($ls_my_profile, 'username', '')}
		on:avatarChange={update_profile_avatar}
		on:clickLogOut={logout_auth}
	/>
</Modal>

<style>
</style>
