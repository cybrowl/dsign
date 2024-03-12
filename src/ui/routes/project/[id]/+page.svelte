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

	import { actor_creator } from '$stores_ref/actors';

	// Auth
	import { auth, init_auth } from '$stores_ref/auth_client';

	// User Data
	import { project_store, is_edit_active, project_actions } from '$stores_ref/data_project';
	import { snap_project_store, snap_preview_store, snap_actions } from '$stores_ref/data_snap';
	import { ls_my_profile } from '$stores_ref/local_storage';

	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation, navigate_to_home_with_notification } from '$stores_ref/page_navigation';
	import { projectTabsState } from '$stores_ref/page_state';

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
	function accept_change(event) {
		console.log('accept_change: ', event.detail);
	}

	function reject_change(event) {
		console.log('reject_change: ', event.detail);
	}

	function remove_topic(event) {
		console.log('remove_topic: ', event.detail);
	}

	function select_topic(event) {
		console.log('select_topic: ', event.detail);
	}

	function send_message(event) {
		console.log('send_message: ', event.detail);
	}

	function select_file(event) {
		console.log('select_file: ', event.detail);
	}

	function download_file(event) {
		console.log('download_file: ', event);
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
			{#if project_tab === 'feedback'}
				<Feedback
					project={$project_store.project}
					on:accept_change={accept_change}
					on:download_file={download_file}
					on:reject_change={reject_change}
					on:remove_topic={remove_topic}
					on:select_file={select_file}
					on:select_topic={select_topic}
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
