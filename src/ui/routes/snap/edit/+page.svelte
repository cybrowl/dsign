<script>
	import { goto } from '$app/navigation';
	import { onDestroy, onMount } from 'svelte';
	import { get, isEmpty } from 'lodash';

	import Login from '$components_ref/Login.svelte';
	import { ImagesEmpty, Images, PageNavigation, SnapUpsertActions } from 'dsign-components';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { FileStorage } from '$utils/file_storage';

	import {
		actor_creator,
		actor_file_scaling_manager,
		actor_file_storage
	} from '$stores_ref/actors';
	import { auth, init_auth } from '$stores_ref/auth_client';
	import { snap_upsert_store, snap_project_store, snap_actions } from '$stores_ref/data_snap';

	import { modal_visible } from '$stores_ref/modal';

	let images = [];
	let is_publishing = false;
	let is_uploading_design_file = false;
	const snap_cid = get($snap_upsert_store, 'snap.canister_id', '');
	const snap_id = get($snap_upsert_store, 'snap.id', '');

	snap_upsert_store.subscribe((store) => {
		images = store.snap.images.filter((image) => image.status !== 'removed');
	});

	onMount(async () => {
		await init_auth();

		if (isEmpty($snap_project_store.project)) {
			goto(`/`);
		}
	});

	onDestroy(async () => {
		//TODO: something
	});

	async function cancel() {
		const project = $snap_project_store.project;

		goto(`/project/${project.name}?id=${project.id}&cid=${project.canister_id}`);
	}

	async function add_images(event) {
		let { imageData } = get(event, 'detail', []);

		snap_actions.add_images_to_snap(imageData);

		is_publishing = true;

		const storage_canister_id_alloc =
			await $actor_file_scaling_manager.actor.get_current_canister_id();
		await auth.file_storage(storage_canister_id_alloc);
		await auth.creator(snap_cid);

		const file_storage = new FileStorage($actor_file_storage.actor);

		const uploadPromises = [];

		if ($actor_file_storage.loggedIn & $actor_creator.loggedIn) {
			imageData.forEach((image) => {
				const imageUploadPromise = file_storage
					.store(image.uint8Array, {
						filename: image.fileName,
						content_type: image.mimeType
					})
					.then((uploadResult) => ({ ...uploadResult, isDesignFile: false }));

				uploadPromises.push(imageUploadPromise);
			});

			// Perform all uploads in parallel
			const uploadResults = await Promise.all(uploadPromises);

			const images_arr = uploadResults
				.filter((result) => !result.isDesignFile)
				.map((result) => result.ok);

			const { ok: added_images } = await $actor_creator.actor.add_images_to_snap(
				snap_id,
				images_arr
			);

			is_publishing = false;
		}
	}

	async function remove_image(event) {
		let image = get(event, 'detail', {});

		snap_actions.remove_image_from_snap(image.id);

		await auth.creator(snap_cid);

		if ($actor_creator.loggedIn) {
			is_publishing = true;

			const { ok: removed_img } = await $actor_creator.actor.delete_image_from_snap(
				snap_id,
				image.id
			);

			is_publishing = false;
		}
	}

	async function attach_file(event) {
		let file = get(event, 'detail', {});

		is_uploading_design_file = true;

		if (
			!file ||
			typeof file.name !== 'string' ||
			typeof file.type !== 'string' ||
			!file.arrayBuffer
		) {
			console.error('Invalid file details.');

			is_uploading_design_file = false;

			throw new Error('Invalid file provided.');
		}

		try {
			const storage_canister_id_alloc =
				await $actor_file_scaling_manager.actor.get_current_canister_id();
			await auth.file_storage(storage_canister_id_alloc);
			await auth.creator(snap_cid);
		} catch (error) {
			console.error('Error during authorization or canister ID retrieval:', error);
			throw new Error('Authorization or canister ID retrieval failed.');
		}

		const file_storage = new FileStorage($actor_file_storage.actor);

		try {
			const file_uint8 = new Uint8Array(await file.arrayBuffer());

			const { ok: file_uploaded } = await file_storage.store(file_uint8, {
				filename: file.name,
				content_type: file.type
			});

			if (!file_uploaded) {
				console.error('File upload failed.');
				throw new Error('File upload was not successful.');
			}

			const snap_args = {
				id: snap_id,
				name: [],
				tags: [],
				design_file: [file_uploaded],
				image_cover_location: []
			};

			const { ok: snap_public, err: err_profile } =
				await $actor_creator.actor.update_snap(snap_args);

			console.log('snap_public: ', snap_public);

			if (!snap_public || err_profile) {
				console.error('Error updating snap:', err_profile);
				throw new Error('Failed to update snap.');
			}
		} catch (error) {
			console.error('Error uploading file or updating snap:', error);
			throw error;
		} finally {
			is_uploading_design_file = false;
		}

		return { success: true };
	}

	async function delete_snap_design_file() {
		snap_actions.remove_design_file();

		is_publishing = true;

		await auth.creator(snap_cid);

		if ($actor_creator.loggedIn) {
			try {
				const { ok: file_deleted, err: err_delete_file } =
					await $actor_creator.actor.delete_snap_design_file(snap_id);
			} catch (error) {
				console.error('Error removing file:', error);
			} finally {
				is_publishing = false;
			}
		}
	}

	async function select_cover_image(event) {
		const { id } = event.detail;

		let image_cover_location = $snap_upsert_store.snap.images.findIndex((img) => img.id === id);

		snap_actions.select_cover_image(image_cover_location);

		await auth.creator(snap_cid);

		if ($actor_creator.loggedIn) {
			is_publishing = true;

			const update_args = {
				id: snap_id,
				name: [],
				design_file: [],
				image_cover_location: [image_cover_location],
				tags: []
			};

			const { ok: updated_snap } = await $actor_creator.actor.update_snap(update_args);

			is_publishing = false;
		}
	}

	async function update_tags(event) {
		const snap_tags = get(event, 'detail', []);

		is_publishing = true;

		await auth.creator(snap_cid);

		if ($actor_creator.loggedIn) {
			try {
				const update_args = {
					id: snap_id,
					name: [],
					design_file: [],
					image_cover_location: [],
					tags: [snap_tags]
				};

				const { ok: updated_snap } = await $actor_creator.actor.update_snap(update_args);
			} catch (error) {
				console.error('Error updating tags:', error);
			} finally {
				is_publishing = false;
			}
		}
	}

	async function snap_name_change(event) {
		const { snap_name } = get(event, 'detail', []);

		is_publishing = true;

		await auth.creator(snap_cid);

		if ($actor_creator.loggedIn) {
			try {
				const update_args = {
					id: snap_id,
					name: [snap_name],
					design_file: [],
					image_cover_location: [],
					tags: []
				};

				const { ok: updated_snap } = await $actor_creator.actor.update_snap(update_args);
			} catch (error) {
				console.error('Error changing name:', error);
			} finally {
				is_publishing = false;
			}
		}
	}
</script>

<svelte:head>
	<title>Snap Edit</title>
</svelte:head>

<main class="grid_layout">
	<div class="navigation_main_layout">
		<PageNavigation
			navigationItems={[]}
			on:home={() => {
				goto('/');
			}}
		>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<div class="content_layout">
		{#if isEmpty($snap_upsert_store.snap.images)}
			<ImagesEmpty content="Please add images" />
		{:else}
			<Images on:remove={remove_image} on:selectCover={select_cover_image} {images} />
		{/if}
	</div>

	<div class="actions_bar_layout">
		<SnapUpsertActions
			on:addImages={add_images}
			on:attachFile={attach_file}
			on:cancel={cancel}
			on:update_tags={update_tags}
			on:snap_name_change={snap_name_change}
			on:removeFile={delete_snap_design_file}
			snap={$snap_upsert_store.snap}
			{is_publishing}
			{is_uploading_design_file}
			is_edit_mode={true}
		/>
	</div>
</main>

<style lang="postcss">
	.grid_layout {
		@apply hidden lg:grid grid-cols-12 gap-y-2 mx-12 2xl:mx-60;
	}
	.navigation_main_layout {
		@apply row-start-1 row-end-auto col-start-1 col-end-13;
	}
	.content_layout {
		@apply row-start-3 row-end-auto col-start-1 col-end-9 mb-10 flex flex-col items-center mr-6;
	}
	.actions_bar_layout {
		@apply row-start-3 row-end-auto col-start-9 col-end-13 mb-10 flex justify-start;
	}
</style>
