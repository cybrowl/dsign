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

	import {
		actor_favorite_main,
		actor_profile,
		actor_project_main,
		actor_snap_main
	} from '$stores_ref/actors';
	import { project_store, project_store_fetching, projects_update } from '$stores_ref/fetch_store';
	import { auth } from '$stores_ref/auth_client';
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

	let isProjectOwner = false;

	onMount(async () => {
		await Promise.all([
			auth.favorite_main(),
			auth.profile(),
			auth.project_main(),
			auth.snap_main()
		]);

		local_snap_creation_design_file.set({ file_name: '', file_type: '', chunk_ids: [] });

		const canister_id = $page.url.searchParams.get('canister_id');
		const project_id = last(get($page, 'url.pathname', '').split('/'));
		let username = '';

		if ($actor_profile.loggedIn) {
			try {
				const { ok: auth_profile } = await $actor_profile.actor.get_profile();
				const project_username = get($project_store, 'project.username', 'x');

				username = get(auth_profile, 'username', 'x');

				isProjectOwner = username === project_username;
			} catch (error) {
				console.log('error: ', error);
			}
		}

		if (isEmpty($project_store.project)) {
			const { ok: project } = await $actor_project_main.actor.get_project(project_id, canister_id);

			isProjectOwner = username === project.username;

			projects_update.update_project(project);
		}
	});

	async function handleAddToFavorites(e) {
		const project_liked = e.detail;

		const project_ref = {
			canister_id: project_liked.canister_id,
			id: project_liked.id
		};

		if ($actor_favorite_main.loggedIn) {
			try {
				const { ok: all_favs, err: err_get_all_favs } =
					await $actor_favorite_main.actor.save_project(project_ref);

				console.log('err_get_all_favs: ', err_get_all_favs);
				console.log('all_favs: ', all_favs);
			} catch (error) {
				console.log('error: call', error);
			}
		} else {
			navigate_to_home_with_notification();
		}
	}

	function handleToggleEditMode(e) {
		is_edit_active.set(get(e, 'detail', false));

		projects_update.deselect_snaps_from_project();
	}

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

		if ($actor_snap_main.loggedIn) {
			const { ok: res, err: error } = await $actor_snap_main.actor.delete_snaps(
				selected_snaps_ids,
				{
					id: project_id,
					canister_id: project_canister_id
				}
			);

			const { ok: project } = await $actor_project_main.actor.get_project(
				project_id,
				project_canister_id
			);

			projects_update.update_project(project);
		} else {
			navigate_to_home_with_notification();
		}
	}

	function handleSnapPreview(e) {
		const snap = e.detail;
		const updated_snap = {
			...snap,
			project: {
				id: $project_store.project.id,
				canister_id: $project_store.project.canister_id,
				name: $project_store.project.name
			}
		};

		snap_preview.set(updated_snap);

		goto('/snap/' + snap.id + '?canister_id=' + snap.canister_id);
	}

	function goToSnapUpsertPage() {
		const project_id = get($project_store, 'project.id', 'x');
		const project_canister_id = get($project_store, 'project.canister_id', 'x');

		goto(`/snap/upsert?project_id=${project_id}&canister_id=${project_canister_id}`);
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
			{#if $projectTabsState.isSnapsSelected && isProjectOwner}
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
					{#if isProjectOwner}
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
					{#if isProjectOwner}
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
		@apply grid lg:hidden h-screen place-items-center text-white text-4xl;
	}
</style>
