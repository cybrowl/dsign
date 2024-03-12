<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { get, isEmpty } from 'lodash';

	import Login from '$components_ref/Login.svelte';
	import {
		CardEmpty,
		Feedback,
		PageNavigation,
		ProjectEditActionsBar,
		ProjectInfo,
		ProjectTabs,
		SnapCard,
		SnapCardCreate,
		SpinnerCircle
	} from 'dsign-components';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { FileStorage } from '$utils/file_storage';

	import {
		actor_creator,
		actor_file_scaling_manager,
		actor_file_storage
	} from '$stores_ref/actors';

	// Auth
	import { auth, init_auth } from '$stores_ref/auth_client';

	// User Data
	import {
		is_edit_active,
		project_actions,
		project_store,
		selected_topic_id
	} from '$stores_ref/data_project';
	import { snap_project_store, snap_preview_store, snap_actions } from '$stores_ref/data_snap';
	import { ls_my_profile } from '$stores_ref/local_storage';

	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation, navigate_to_home_with_notification } from '$stores_ref/page_navigation';

	project_actions.deselect_snaps();
	is_edit_active.set(false);

	const project_id = $page.url.searchParams.get('id');
	const canister_id = $page.url.searchParams.get('cid');
	let project_tab = $page.url.searchParams.get('tab') || 'snaps';

	onMount(async () => {
		await init_auth();

		await auth.creator(canister_id);

		try {
			project_actions.fetching();

			const { ok: project, err: error } = await $actor_creator.actor.get_project(project_id);

			console.log('project: ', project);

			project_store.set({ isFetching: false, project });
		} catch (error) {
			console.log('error: ', error);
		}
	});

	// ------------------------- Edit Mode -------------------------
	function toggle_edit_mode(e) {
		is_edit_active.set(get(e, 'detail', false));

		project_actions.deselect_snaps();
	}

	// ------------------------- Nav -------------------------
	function goto_snap_preview(e) {
		const snap = e.detail;

		snap_project_store.set({ isFetching: false, mode: 'preview', project: $project_store.project });
		snap_preview_store.set({ isFetching: false, snap: snap });

		goto('/snap/' + snap.id + '?cid=' + snap.canister_id);
	}

	function goto_snap_create() {
		snap_project_store.set({ isFetching: false, mode: 'create', project: $project_store.project });

		snap_actions.set_empty_snap();

		goto(`/snap/create`);
	}

	// ------------------------- API -------------------------
	async function delete_snaps() {
		const selected_snap_ids = project_actions.get_selected_snap_ids();

		project_actions.remove_selected_snaps();
		is_edit_active.set(false);

		await auth.creator(get($ls_my_profile, 'canister_id', ''));

		if ($actor_creator.loggedIn) {
			const { ok: deleted_snaps, err: err_profile } =
				await $actor_creator.actor.delete_snaps(selected_snap_ids);

			console.log('deleted: ', deleted_snaps);
			console.log('err_profile: ', err_profile);
		} else {
			navigate_to_home_with_notification();
		}
	}

	async function add_project_to_favs(e) {
		const project_liked = e.detail;

		//TODO: add project to favs
	}

	// ------------------------- Feedback -------------------------

	async function send_message(event) {
		const { content, selected_topic } = event.detail;

		console.log('content: ', content);
		console.log('selected_topic: ', selected_topic);

		await auth.creator(canister_id);

		if ($actor_creator.loggedIn) {
			const { ok: topic, err: err_topic } = await $actor_creator.actor.add_message_to_topic({
				project_id: project_id,
				snap_id: selected_topic.id,
				message: [content],
				design_file: []
			});

			project_actions.fetching();

			const { ok: project } = await $actor_creator.actor.get_project(project_id);

			selected_topic_id.set(selected_topic.id);

			project_actions.update_project(project);
		}
	}

	async function add_file_to_topic(event) {
		const { file, selected_topic } = event.detail;

		console.log('file: ', file);
		console.log('selected_topic: ', selected_topic);

		const storage_canister_id_alloc =
			await $actor_file_scaling_manager.actor.get_current_canister_id();
		await auth.file_storage(storage_canister_id_alloc);
		await auth.creator(canister_id);

		if (file && $actor_creator.loggedIn) {
			try {
				const file_storage = new FileStorage($actor_file_storage.actor);

				const file_uint8 = new Uint8Array(await file.arrayBuffer());

				const { ok: file_public } = await file_storage.store(file_uint8, {
					filename: file.name,
					content_type: file.type
				});

				const { ok: topic, err: err_topic } = await $actor_creator.actor.add_file_to_topic({
					project_id: project_id,
					snap_id: selected_topic.id,
					message: [],
					design_file: [file_public]
				});

				project_actions.fetching();

				const { ok: project } = await $actor_creator.actor.get_project(project_id);

				project_actions.update_project(project);
			} catch (error) {
				// TODO: log err
			}
		}

		//TODO: store the file in storage
		//TODO: send that file to `creator.add_file_to_topic`
	}

	function remove_file_from_topic(event) {
		const file = event.detail;

		//TODO: store the file in storage
		//TODO: send that file to `creator.remove_file_from_topic`
	}

	function remove_topic(event) {
		console.log('remove_topic: ', event.detail);
	}

	function reject_change(event) {
		console.log('reject_change: ', event.detail);
	}

	function accept_change(event) {
		//TODO: this might not get done in time
		console.log('accept_change: ', event.detail);
	}

	function tab_change(event) {
		project_tab = event.detail.selected_tab;

		goto(`?id=${project_id}&cid=${canister_id}&tab=${project_tab}`, {
			replaceState: true,
			noscroll: true
		});
	}
</script>

<svelte:head>
	<title>Project</title>
</svelte:head>

<main class="grid_layout">
	<div class="navigation_main_layout">
		<PageNavigation
			navigationItems={$page_navigation.navigationItems}
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

	<!-- Fetching Project -->
	{#if $project_store.isFetching === true}
		<!-- Fetching Project -->
		<div class="loading_layout">
			<SpinnerCircle />
		</div>
	{/if}

	<!-- Project -->
	{#if isEmpty($project_store.project) === false}
		<!-- Project Info Header -->
		<div class="project_info_layout">
			<ProjectInfo project={$project_store.project} on:saveToFavorites={add_project_to_favs} />
		</div>

		<!-- ProjectsTabs & ProjectEditActionsBar -->
		<div class="project_tabs_layout">
			<ProjectTabs selected_tab={project_tab} on:tabSelected={tab_change} />

			{#if project_tab === 'snaps' && get($project_store, 'project.is_owner', false)}
				<ProjectEditActionsBar
					isEditActive={$is_edit_active}
					on:toggleEditMode={toggle_edit_mode}
					on:clickRemove={delete_snaps}
				/>
			{/if}
		</div>

		<div class="snaps_layout">
			{#if project_tab === 'snaps'}
				<!-- No Snaps Found -->
				{#if isEmpty($project_store.project.snaps) && $project_store.isFetching === false}
					{#if get($project_store, 'project.is_owner', false)}
						<SnapCardCreate on:clickSnapCardCreate={goto_snap_create} />
					{:else}
						<CardEmpty
							name="snap_empty"
							content="No snaps found"
							view_size={{ width: '64', height: '64' }}
						/>
					{/if}
				{/if}

				<!-- Snaps -->
				{#if $project_store.project.snaps && $project_store.project.snaps.length > 0}
					{#each $project_store.project.snaps as snap (snap.id)}
						<SnapCard {snap} showEditMode={$is_edit_active} on:clickCard={goto_snap_preview} />
					{/each}
					{#if get($project_store, 'project.is_owner', false)}
						<SnapCardCreate on:clickSnapCardCreate={goto_snap_create} />
					{/if}
				{/if}
			{/if}
		</div>

		<div class="feedback_layout">
			{#if ($project_store.isFetching === false || $selected_topic_id) & (project_tab === 'feedback')}
				<Feedback
					project={$project_store.project}
					selected_topic_id={$selected_topic_id}
					on:accept_change={accept_change}
					on:reject_change={reject_change}
					on:remove_topic={remove_topic}
					on:select_file={add_file_to_topic}
					on:send_message={send_message}
				/>
			{/if}
		</div>
	{/if}

	<!-- Mobile Not Supported -->
	<div class="not_supported">
		<h1>Sorry, Mobile Not Supported</h1>
	</div>
</main>

<style lang="postcss">
	.grid_layout {
		@apply hidden lg:grid grid-cols-12 relative mx-12 2xl:mx-60;
	}
	.navigation_main_layout {
		@apply row-start-1 row-end-auto col-start-1 col-end-13;
	}
	.loading_layout {
		position: fixed;
		z-index: 30;
		top: 42%;
		left: 50%;
		transform: translate(-50%, -50%);
	}
	.project_info_layout {
		@apply row-start-2 row-end-auto relative col-start-1 col-end-13;
	}
	.project_tabs_layout {
		@apply row-start-3 row-end-auto col-start-1 col-end-13 items-center justify-between mt-12 mb-6;
	}
	.snaps_layout {
		@apply row-start-4 row-end-auto hidden lg:grid  grid-cols-4 col-start-1 col-end-13 gap-x-6 gap-y-12 mb-16;
	}
	/* .coming_soon_layout {
		@apply row-start-4 row-end-auto grid col-start-3 col-end-13;
	} */
	.feedback_layout {
		@apply row-start-4 row-end-auto hidden lg:grid grid-cols-12 col-start-1 col-end-13 gap-x-6 gap-y-12 mb-16;
	}
	.not_supported {
		display: grid;
		height: 100vh;
		justify-items: center;
		align-items: center;
		color: white;
		font-size: 2.25rem;
	}
	@media (min-width: 1024px) {
		.not_supported {
			display: none;
		}
	}
</style>
