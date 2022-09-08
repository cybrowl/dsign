<script>
	import { onDestroy } from 'svelte';

	import SnapCreation from 'dsign-components/components/SnapCreation.svelte';
	import SnapCreationPublishing from 'dsign-components/components/SnapCreationPublishing.svelte';
	import get from 'lodash/get.js';
	import Modal from 'dsign-components/components/Modal.svelte';

	import { actor_snap_main, snap_store } from '../store/actor_snap_main';
	import { actor_assets_file_chunks } from '../store/actor_assets_file_chunks';
	import { actor_assets_img_staging } from '../store/actor_assets_img_staging';
	import { isSnapCreationModalVisible } from '../store/modal';

	let is_publishing = false;

	onDestroy(() => (is_publishing = false));

	function handleCloseModal(all_snaps) {
		isSnapCreationModalVisible.update((isSnapCreationModalVisible) => !isSnapCreationModalVisible);

		snap_store.set({ isFetching: false, snaps: [...all_snaps.ok] });
	}

	async function commitImgAssetsToStaging(images) {
		let promises = [];

		console.log('images', images);

		images.forEach(async function (image) {
			const args = {
				data: image,
				file_format: 'png'
			};

			promises.push($actor_assets_img_staging.actor.create_asset(args));
		});

		try {
			return await Promise.all(promises);
		} catch (error) {
			console.log('error: ', error);
			return [];
		}
	}

	async function commitFileAssetChunks(snap) {
		const uploadChunk = async ({ chunk, file_name }) => {
			return $actor_assets_file_chunks.actor.create_chunk({
				data: [...chunk],
				file_name: file_name
			});
		};

		const file_name = snap.file.name || '';

		const promises = [];

		const chunkSize = 2000000;

		for (let start = 0; start < snap.file_array_buffer.length; start += chunkSize) {
			const chunk = snap.file_array_buffer.slice(start, start + chunkSize);

			promises.push(
				uploadChunk({
					file_name,
					chunk
				})
			);
		}

		let chunk_ids = await Promise.all(promises);

		return [
			{
				is_public: snap.is_public,
				content_type: snap.file.type,
				chunk_ids: chunk_ids
			}
		];
	}

	async function handleSnapCreation(e) {
		const snap = get(e, 'detail');
		let img_asset_ids = [];
		let file_asset = [];

		is_publishing = true;

		img_asset_ids = await commitImgAssetsToStaging(snap.images);

		let has_invalid_img = false;

		img_asset_ids.forEach(function (val) {
			if (val == 0) {
				has_invalid_img = true;
			}
		});

		if (snap.file !== null) {
			file_asset = await commitFileAssetChunks(snap);
		}

		const create_snap_args = {
			title: snap.title,
			image_cover_location: snap.cover_image_location,
			img_asset_ids: img_asset_ids,
			file_asset
		};

		const created_snap_res = await $actor_snap_main.actor.create_snap(create_snap_args);

		const all_snaps = await $actor_snap_main.actor.get_all_snaps();

		handleCloseModal(all_snaps);
	}
</script>

<Modal
	on:closeModal={handleCloseModal}
	modalHeaderVisible={!is_publishing}
	isModalLocked={is_publishing}
>
	{#if is_publishing === true}
		<SnapCreationPublishing />
	{:else}
		<SnapCreation on:create_snap={handleSnapCreation} />
	{/if}
</Modal>

<style>
</style>
