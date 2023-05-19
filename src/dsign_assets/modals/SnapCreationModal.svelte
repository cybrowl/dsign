<!-- <script>
	import { onMount, onDestroy } from 'svelte';
	import get from 'lodash/get.js';

	import SnapCreation from 'dsign-components/components/SnapCreation.svelte';
	import SnapCreationPublishing from 'dsign-components/components/SnapCreationPublishing.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';

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
	import { projects_update } from '$stores_ref/fetch_store';
	import modal_update from '$stores_ref/modal';

	let is_publishing = false;
	export let project_ref = {};

	onMount(async () => {
		await Promise.all([auth_assets_file_staging(), auth_assets_img_staging(), auth_snap_main()]);
	});

	onDestroy(() => (is_publishing = false));

	function handleCloseModal() {
		modal_update.change_visibility('snap_creation');
	}

	async function commitImgAssetsToStaging(images) {
		let promises = [];

		images.forEach(async function (image) {
			// note: image file_format is checked by assets_img_staging actor
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

	async function commitFileAssetChunksToStaging(snap) {
		const uploadChunk = async ({ chunk, file_name }) => {
			return $actor_assets_file_staging.actor.create_chunk({
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
		//TODO: project the snap is being created in

		is_publishing = true;

		if (
			$actor_assets_file_staging.loggedIn &&
			$actor_assets_img_staging.loggedIn &&
			$actor_snap_main.loggedIn
		) {
			try {
				const imgAssetPromise = commitImgAssetsToStaging(snap.images);
				const fileAssetPromise = snap.file
					? commitFileAssetChunksToStaging(snap)
					: Promise.resolve([]);

				const [img_asset_ids, file_asset] = await Promise.all([imgAssetPromise, fileAssetPromise]);

				const has_invalid_img = img_asset_ids.some((val) => val === 0);

				if (!has_invalid_img) {
					const create_snap_args = {
						title: snap.title,
						image_cover_location: snap.cover_image_location,
						img_asset_ids: img_asset_ids,
						project: {
							id: project_ref.id,
							canister_id: project_ref.canister_id
						},
						file_asset
					};

					console.log('create_snap_args: ', create_snap_args);

					const { ok: created_snap } = await $actor_snap_main.actor.create_snap(create_snap_args);

					const { ok: project } = await $actor_project_main.actor.get_project(
						project_ref.id,
						project_ref.canister_id
					);

					projects_update.update_project(project);

					//TODO:
					// save snap id to localstorage to later send to actor_snap_main in root/[username]
					// {snap_id: xxx, tags: ["xx", "yy"]}
					// you can only save snap_id here so it has to be two arrays that are created
					// make sure all the tags are sent in lowercase
				}

				modal_update.change_visibility('snap_creation');
			} catch (error) {
				console.error('Error during snap creation:', error);
				// You can display an error message to the user or handle the error as needed
			} finally {
				// is_publishing = false;
			}
		}
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
</style> -->
