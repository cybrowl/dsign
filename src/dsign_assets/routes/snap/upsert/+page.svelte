<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onDestroy, onMount } from 'svelte';

	import { get, findIndex, isEmpty } from 'lodash';
	import { replacer, reviver } from '../../../utils/big_int';

	import Login from '$components_ref/Login.svelte';
	import { ImagesEmpty, Images, PageNavigation, SnapUpsertActions } from 'dsign-components-v2';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import {
		actor_assets_file_staging,
		actor_assets_img_staging,
		actor_snap_main,
		actor_project_main
	} from '$stores_ref/actors';
	import {
		auth_assets_file_staging,
		auth_assets_img_staging,
		auth_snap_main
	} from '$stores_ref/auth_client';
	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation, snap_creation } from '$stores_ref/page_navigation';
	import { disable_project_store_reset } from '$stores_ref/page_state';
	import { local_snap_creation_design_file } from '$stores_ref/local_storage';

	let cover_img = {};
	let is_publishing = false;
	let is_uploading_design_file = false;

	onMount(async () => {
		snap_creation.update((value) => ({
			...value,
			file_asset: {
				...value.file_asset,
				file_name: $local_snap_creation_design_file.file_name
			}
		}));

		await Promise.all([auth_assets_file_staging(), auth_assets_img_staging(), auth_snap_main()]);
	});

	onDestroy(async () => {
		$snap_creation = {
			id: '',
			images: [],
			file_asset: {
				file_name: '',
				file_unit8: []
			}
		};
	});

	async function commitFileAssetChunksToStaging(file) {
		if (file.size === 0) {
			// TODO: error
			return 'File Empty';
		}

		const promises = [];
		const chunkSize = 2000000;

		const file_name = get(file, 'name', '');
		const file_type = get(file, 'type', '');
		const file_array_buffer = file && new Uint8Array(await file.arrayBuffer());

		$snap_creation.file_asset.file_name = file_name;
		$snap_creation.file_asset.file_unit8 = file_array_buffer;

		const uploadChunk = async ({ chunk, file_name }) => {
			return $actor_assets_file_staging.actor.create_chunk({
				data: [...chunk],
				file_name: file_name
			});
		};

		for (let start = 0; start < file_array_buffer.length; start += chunkSize) {
			const chunk = file_array_buffer.slice(start, start + chunkSize);

			promises.push(
				uploadChunk({
					file_name,
					chunk
				})
			);
		}

		// TODO: make sure all the chunks succeed
		let chunk_ids = await Promise.all(promises);

		return {
			file_name,
			file_type,
			chunk_ids
		};
	}

	async function handleAttachFile(event) {
		let file = get(event, 'detail', {});

		is_uploading_design_file = true;

		const design_file_asset = await commitFileAssetChunksToStaging(file);

		const chunk_ids_big_int_replaced = JSON.stringify(design_file_asset.chunk_ids, replacer);

		local_snap_creation_design_file.set({
			...design_file_asset,
			chunk_ids: chunk_ids_big_int_replaced
		});

		is_uploading_design_file = false;
	}

	function handleRemoveFile(event) {
		let file = event.detail;

		// delete from staging storage
		// delete from snap

		$snap_creation.file_asset.file_name = '';
		$snap_creation.file_asset.file_unit8 = [];
	}

	function generateId() {
		return Math.random().toString(36).substr(2, 9);
	}

	function handleAddImages(event) {
		let { img_data_urls, images_unit8Arrays } = event.detail;

		img_data_urls.forEach(({ dataUrl, mimeType }, index) => {
			let newImage = {
				canister_id: '',
				id: generateId(),
				url: dataUrl,
				mimeType,
				data: images_unit8Arrays[index]
			};

			if ($snap_creation.images.length <= 12) {
				$snap_creation.images = [...$snap_creation.images, newImage];
			}
		});

		console.log('snap_creation: ', $snap_creation);
	}

	function handleSelectCover(event) {
		cover_img = event.detail;
	}

	function handleRemoveImg(event) {
		const image_id = event.detail;

		$snap_creation.images = $snap_creation.images.filter((image) => image.id !== image_id);
	}

	function handleCancel() {
		disable_project_store_reset.set(true);

		const project_id = $page.url.searchParams.get('project_id');
		const canister_id = $page.url.searchParams.get('canister_id');

		goto(`/project/${project_id}?canister_id=${canister_id}`);
	}

	async function commitImgAssetsToStaging(images) {
		if (!Array.isArray(images)) {
			console.error('images must be an array');
			return [];
		}

		if (
			!$actor_assets_file_staging.loggedIn ||
			!$actor_assets_img_staging.loggedIn ||
			!$actor_snap_main.loggedIn
		) {
			console.error('Not logged in');
			return [];
		}

		let promises = images.map(async function (image) {
			if (!image.data || !image.mimeType) {
				console.error('image object must contain data and mimeType properties');
				return null;
			}

			try {
				return await $actor_assets_img_staging.actor.create_asset({
					data: image.data,
					file_format: image.mimeType
				});
			} catch (error) {
				console.error('Error creating asset:', error);
				return null;
			}
		});

		try {
			return await Promise.all(promises);
		} catch (error) {
			console.error('Error:', error);
			return [];
		}
	}

	async function handlePublish(event) {
		disable_project_store_reset.set(false);

		const { snap_name } = event.detail;

		is_publishing = true;

		const project_id = $page.url.searchParams.get('project_id');
		const canister_id = $page.url.searchParams.get('canister_id');

		try {
			const image_ids = await commitImgAssetsToStaging($snap_creation.images);

			let image_cover_location = findIndex(
				$snap_creation.images,
				(img) => img.id === get(cover_img, 'id', '')
			);
			image_cover_location = image_cover_location === -1 ? 0 : image_cover_location;

			const file_chunks = $local_snap_creation_design_file.chunk_ids;
			const file_type = $local_snap_creation_design_file.file_type;

			const design_file_chunk_ids = !isEmpty(file_chunks) && JSON.parse(file_chunks, reviver);
			const file_asset = {
				is_public: true,
				content_type: file_type,
				chunk_ids: design_file_chunk_ids
			};

			const create_snap_args = {
				title: snap_name,
				image_cover_location: image_cover_location,
				img_asset_ids: image_ids,
				project: {
					id: project_id,
					canister_id: canister_id
				},
				file_asset: isEmpty(file_chunks) ? [] : file_asset
			};

			const { ok: created_snap, err: snap_creation_failed } =
				await $actor_snap_main.actor.create_snap(create_snap_args);

			goto(`/project/${project_id}?canister_id=${canister_id}`);

			// projects_update.update_project(project);
		} catch (error) {
			console.log('error: ', error);
			is_publishing = false;
		}
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
			<Images
				images={$snap_creation.images}
				on:remove={handleRemoveImg}
				on:selectCover={handleSelectCover}
			/>
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
			is_publishing={is_uploading_design_file || is_publishing}
			{is_uploading_design_file}
		/>
	</div>
</main>
