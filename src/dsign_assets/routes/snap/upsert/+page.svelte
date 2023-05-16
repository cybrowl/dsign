<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	import { get, set, isEmpty } from 'lodash';

	import Login from '$components_ref/Login.svelte';
	import { ImagesEmpty, Images, PageNavigation, SnapUpsertActions } from 'dsign-components-v2';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { actor_snap_main } from '$stores_ref/actors';
	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation, snap_creation } from '$stores_ref/page_navigation';
	import { disable_project_store_reset } from '$stores_ref/page_state';

	disable_project_store_reset.set(true);

	onMount(async () => {});

	async function handleAttachFile(event) {
		let file = event.detail;

		let file_array_buffer = file && new Uint8Array(await file.arrayBuffer());
		set($snap_creation, 'file_asset.file_name', file.name);
		set($snap_creation, 'file_asset.file_unit8', file_array_buffer);

		// add to staging storage
		// add to chunks saved to local storage
	}

	function handleRemoveFile(event) {
		let file = event.detail;

		// delete from staging storage
		set($snap_creation, 'file_asset.file_name', '');
		set($snap_creation, 'file_asset.file_unit8', []);
	}

	function generateId() {
		return Math.random().toString(36).substr(2, 9);
	}

	function handleAddImages(event) {
		let { snap_base64_images, images_unit8Arrays } = event.detail;

		console.log('page: images_unit8Arrays: ', images_unit8Arrays);
		console.log('snap_creation: ', $snap_creation);

		set($snap_creation, 'images', get($snap_creation, 'images', []));
		set($snap_creation, 'images_unit8', get($snap_creation, 'images_unit8', []));

		$snap_creation.images_unit8 = [...$snap_creation.images_unit8, ...images_unit8Arrays];

		snap_base64_images.forEach((url, index) => {
			let newImage = {
				canister_id: '',
				id: generateId(),
				url: url
			};

			if ($snap_creation.images.length <= 12) {
				$snap_creation.images = [...$snap_creation.images, newImage];
			}
		});
	}

	function handleCancel() {
		console.log('cancel');
	}

	function handlePublish() {
		console.log('publish');
	}
</script>

<svelte:head>
	<title>Snap Upsert</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 ml-12 mr-12">
	<div class="row-start-1 row-end-auto col-start-1 col-end-13">
		<PageNavigation navigationItems={$page_navigation.navigationItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<div class="row-start-3 row-end-auto col-start-1 col-end-9 mb-10 flex flex-col items-center mr-6">
		{#if isEmpty($snap_creation.images)}
			<ImagesEmpty content="Please add images" />
		{:else}
			<Images images={$snap_creation.images} />
		{/if}
	</div>

	<div class="row-start-3 row-end-auto col-start-9 col-end-13 mb-10 flex justify-start">
		<SnapUpsertActions
			on:attachFile={handleAttachFile}
			on:removeFile={handleRemoveFile}
			on:addImages={handleAddImages}
			on:cancel={handleCancel}
			on:publish={handlePublish}
			snap={$snap_creation}
		/>
	</div>
</main>
