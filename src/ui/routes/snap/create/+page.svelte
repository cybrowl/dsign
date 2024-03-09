<script>
	import { get, isEmpty } from 'lodash';
	import { goto } from '$app/navigation';
	import { onDestroy, onMount } from 'svelte';

	import { ImagesEmpty, Images, PageNavigation, SnapUpsertActions } from 'dsign-components';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import Login from '$components_ref/Login.svelte';

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

	snap_upsert_store.subscribe((store) => {
		images = store.snap.images.filter((image) => image.status !== 'removed');
	});

	onMount(async () => {
		await init_auth();

		//TODO: something
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

	function add_images(event) {
		let { imageData } = get(event, 'detail', []);

		snap_actions.add_images_to_snap(imageData);
	}

	async function remove_image(event) {
		let image = get(event, 'detail', {});

		snap_actions.remove_image_from_snap(image.id);
	}

	function attach_file(event) {
		let file = get(event, 'detail', {});

		snap_actions.add_design_file(file);
	}

	async function remove_file() {
		snap_actions.remove_design_file();
	}

	async function select_cover_image(event) {
		const { id } = event.detail;

		let image_cover_location = $snap_upsert_store.snap.images.findIndex((img) => img.id === id);

		snap_actions.select_cover_image(image_cover_location);
	}

	async function publish(event) {
		const { snap_name, tags_added } = event.detail;
		const snap = get($snap_upsert_store, 'snap', {});
		const project_id = get($snap_project_store, 'project.id', '');
		const canister_id = get($snap_project_store, 'project.canister_id', '');
		const file = get(snap, 'design_file[0]', null);
		const images = get(snap, 'images', []);

		is_publishing = true;

		const storage_canister_id_alloc =
			await $actor_file_scaling_manager.actor.get_current_canister_id();
		await auth.file_storage(storage_canister_id_alloc);
		await auth.creator(canister_id);

		const file_storage = new FileStorage($actor_file_storage.actor);

		// Initialize an array to hold all upload promises
		const uploadPromises = [];

		// If a file is present, add its upload promise to the array
		if (file) {
			const file_uint8 = new Uint8Array(await file.arrayBuffer());
			const fileUploadPromise = file_storage
				.store(file_uint8, {
					filename: file.name,
					content_type: file.type
				})
				.then((uploadResult) => ({ ...uploadResult, isDesignFile: true }));
			uploadPromises.push(fileUploadPromise);
		}

		// Add image upload promises to the array
		images.forEach((image) => {
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

		// Separate file and images from the results
		const filePublic = uploadResults.find((result) => result.isDesignFile)?.ok;
		const images_arr = uploadResults
			.filter((result) => !result.isDesignFile)
			.map((result) => result.ok);

		const snap_args = {
			project_id,
			name: snap_name,
			tags: [tags_added],
			image_cover_location: snap.image_cover_location,
			design_file: filePublic ? [filePublic] : [],
			images: images_arr
		};

		const { ok: profile, err: err_profile } = await $actor_creator.actor.create_snap(snap_args);

		if (profile) {
			cancel();
		}

		is_publishing = false;
	}
</script>

<svelte:head>
	<title>Snap Create</title>
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
			on:publish={publish}
			on:removeFile={remove_file}
			snap={$snap_upsert_store.snap}
			{is_publishing}
			is_uploading_design_file={false}
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
