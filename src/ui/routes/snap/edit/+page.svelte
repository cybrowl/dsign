<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onDestroy, onMount } from 'svelte';
	import { get, findIndex, isEmpty } from 'lodash';

	import Login from '$components_ref/Login.svelte';
	import { ImagesEmpty, Images, PageNavigation, SnapUpsertActions } from 'dsign-components';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { FileStorage } from '$utils/file_storage';

	import {
		actor_creator,
		actor_file_scaling_manager,
		actor_file_storage,
		actor_username_registry
	} from '$stores_ref/actors';
	import { auth, init_auth } from '$stores_ref/auth_client';
	import { snap_upsert_store, snap_project_store, snap_actions } from '$stores_ref/data_snap';

	import { modal_visible } from '$stores_ref/modal';

	let images = [];
	let is_publishing = false;
	const snap_cid = get($snap_upsert_store, 'snap.canister_id', '');
	const snap_id = get($snap_upsert_store, 'snap.id', '');

	snap_upsert_store.subscribe((store) => {
		images = store.snap.images.filter((image) => image.status !== 'removed');
	});

	onMount(async () => {
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

		await auth.creator(snap_cid);

		if ($actor_creator.loggedIn) {
			is_publishing = true;

			const { ok: removed_img } = await $actor_creator.actor.delete_image_from_snap(
				snap_id,
				image.id
			);

			console.log('removed_img: ', removed_img);

			is_publishing = false;
		}
	}

	function attach_file(event) {
		let file = get(event, 'detail', {});

		snap_actions.add_design_file(file);

		//TODO: API call to add
	}

	async function remove_file() {
		snap_actions.remove_design_file();

		//TODO: API call to remove
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

			console.log('updated_snap: ', updated_snap);

			is_publishing = false;
		}
	}

	async function publish() {
		console.log('snap_upsert_store: ', $snap_upsert_store.snap);
	}
</script>

<svelte:head>
	<title>Snap Upsert</title>
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
			is_edit_mode={true}
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
