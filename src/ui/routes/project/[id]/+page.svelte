<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { get, isEmpty, last } from 'lodash';

	import Login from '$components_ref/Login.svelte';
	import {
		CardEmpty,
		ComingSoon,
		SpinnerCircle,
		PageNavigation,
		ProjectEditActionsBar,
		ProjectInfo,
		ProjectTabs,
		SnapCard,
		SnapCardCreate
	} from 'dsign-components';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { actor_creator, actor_username_registry } from '$stores_ref/actors';
	import { project_store, project_actions } from '$stores_ref/data_project';

	import { project_store_fetching, projects_update } from '$stores_ref/fetch_store';
	import { auth, init_auth } from '$stores_ref/auth_client';
	import { modal_visible } from '$stores_ref/modal';
	import {
		snap_preview,
		page_navigation,
		navigate_to_home_with_notification
	} from '$stores_ref/page_navigation';
	import {
		disable_project_store_reset,
		is_edit_active,
		projectTabsState
	} from '$stores_ref/page_state';
	import { local_snap_creation_design_file } from '$stores_ref/local_storage';

	projects_update.deselect_snaps_from_project();
	is_edit_active.set(false);

	if ($disable_project_store_reset === false) {
		project_store_fetching();
	}

	onMount(async () => {
		await init_auth();

		const project_id = $page.url.searchParams.get('id');
		const canister_id = $page.url.searchParams.get('cid');

		await auth.creator(canister_id);

		if ($actor_creator.loggedIn) {
			try {
				project_actions.fetching();

				const { ok: project, err: error } = await $actor_creator.actor.get_project(project_id);

				project_store.set({ isFetching: false, project });
			} catch (error) {
				console.log('error: ', error);
			}
		}
	});

	// ------------------------- Edit Mode -------------------------
	function handleToggleEditMode(e) {
		is_edit_active.set(get(e, 'detail', false));

		projects_update.deselect_snaps_from_project();
	}

	// ------------------------- Nav -------------------------
	function handleSnapPreview(e) {
		const snap = e.detail;
		const updated_snap = {
			...snap,
			project_name: $project_store.project.name,
			project_ref: [
				{
					id: $project_store.project.id,
					canister_id: $project_store.project.canister_id
				}
			]
		};

		snap_preview.set(updated_snap);

		goto('/snap/' + snap.id + '?canister_id=' + snap.canister_id);
	}

	function goToSnapUpsertPage() {
		const project_id = get($project_store, 'project.id', 'x');
		const project_canister_id = get($project_store, 'project.canister_id', 'x');

		goto(`/snap/upsert?project_id=${project_id}&canister_id=${project_canister_id}`);
	}

	// ------------------------- API -------------------------

	async function handleDeleteSnaps() {
		const snaps = get($project_store.project, 'snaps', []);
		const project_id = get($project_store, 'project.id', 'x');
		const project_canister_id = get($project_store, 'project.canister_id', 'x');

		const selected_snaps = snaps.filter((snap) => snap.isSelected === true);
		const selected_snaps_ids = selected_snaps.map((snap) => snap.id);

		if (selected_snaps_ids.length === 0) {
			//TODO: Notification
			return 'Nothing to Delete';
		}

		handleToggleEditMode({ detail: false });

		const snaps_kept = snaps.filter((snap) => snap.isSelected === false);

		projects_update.delete_snaps_from_project(snaps_kept);

		const creator_logged_in = false;
		if (creator_logged_in) {
			// TODO: delete snaps

			projects_update.update_project(project);
		} else {
			navigate_to_home_with_notification();
		}
	}

	async function handleAddToFavorites(e) {
		const project_liked = e.detail;

		const project_ref = {
			canister_id: project_liked.canister_id,
			id: project_liked.id
		};

		const creator_logged_in = false;
		if (creator_logged_in) {
			try {
				// TODO: save project to favorites
			} catch (error) {
				console.log('error: call', error);
			}
		} else {
			navigate_to_home_with_notification();
		}
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
			<ProjectInfo project={$project_store.project} on:saveToFavorites={handleAddToFavorites} />
		</div>

		<!-- ProjectsTabs & ProjectEditActionsBar -->
		<div class="project_tabs_layout">
			<ProjectTabs
				selectedTabState={$projectTabsState}
				on:selectSnapsTab={(e) => projectTabsState.set(e.detail)}
				on:selectFeedbackTab={(e) => projectTabsState.set(e.detail)}
			/>
			{#if $projectTabsState.isSnapsSelected && get($project_store, 'project.is_owner', false)}
				<ProjectEditActionsBar
					isEditActive={$is_edit_active}
					on:toggleEditMode={handleToggleEditMode}
					on:clickRemove={handleDeleteSnaps}
				/>
			{/if}
		</div>

		<div class="content_layout">
			{#if $projectTabsState.isSnapsSelected}
				<!-- No Snaps Found -->
				{#if isEmpty($project_store.project.snaps) && $project_store.isFetching === false}
					{#if get($project_store, 'project.is_owner', false)}
						<SnapCardCreate on:clickSnapCardCreate={goToSnapUpsertPage} />
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
					{#each $project_store.project.snaps as snap}
						<SnapCard {snap} showEditMode={$is_edit_active} on:clickCard={handleSnapPreview} />
					{/each}
					{#if get($project_store, 'project.is_owner', false)}
						<SnapCardCreate on:clickSnapCardCreate={goToSnapUpsertPage} />
					{/if}
				{/if}
			{/if}

			{#if $projectTabsState.isFeedbackSelected}
				<div class="coming_soon_layout">
					<ComingSoon />
				</div>
			{/if}

			{#if $projectTabsState.isChangesSelected}
				<div class="coming_soon_layout">
					<ComingSoon />
				</div>
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
	.content_layout {
		@apply row-start-4 row-end-auto hidden lg:grid  grid-cols-4 col-start-1 col-end-13 gap-x-6 gap-y-12 mb-16;
	}
	.coming_soon_layout {
		@apply row-start-4 row-end-auto grid col-start-3 col-end-13;
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
