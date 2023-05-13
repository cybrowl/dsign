<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import get from 'lodash/get';
	import last from 'lodash/last';
	import isEmpty from 'lodash/isEmpty';

	import Login from '$components_ref/Login.svelte';

	import {
		PageNavigation,
		ProjectEditActionsBar,
		ProjectInfo,
		ProjectTabs,
		SnapCard,
		SnapCardCreate
	} from 'dsign-components-v2';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import SnapCreationModal from '$modals_ref/SnapCreationModal.svelte';

	import {
		actor_favorite_main,
		actor_profile,
		actor_project_main,
		actor_snap_main
	} from '$stores_ref/actors';
	import { project_store, project_store_fetching, projects_update } from '$stores_ref/fetch_store';
	import {
		auth_favorite_main,
		auth_profile,
		auth_project_main,
		auth_snap_main
	} from '$stores_ref/auth_client';
	import modal_update, { modal_visible } from '$stores_ref/modal';
	import page_navigation_update, {
		snap_preview,
		page_navigation
	} from '$stores_ref/page_navigation';
	import {
		disable_project_store_reset,
		is_edit_active,
		projectTabsState
	} from '$stores_ref/page_state';

	let isProjectOwner = false;
	let project_ref = {};

	projects_update.deselect_snaps_from_project();
	is_edit_active.set(false);

	if ($disable_project_store_reset === false) {
		project_store_fetching();
	} else {
		disable_project_store_reset.set(false);
	}

	onMount(async () => {
		await Promise.all([
			auth_favorite_main(),
			auth_profile(),
			auth_project_main(),
			auth_snap_main()
		]);

		const canister_id = $page.url.searchParams.get('canister_id');
		const project_id = last(get($page, 'url.pathname', '').split('/'));

		try {
			Promise.all([
				$actor_profile.actor.get_profile(),
				$actor_project_main.actor.get_project(project_id, canister_id)
			]).then(async ([auth_profile_, project_]) => {
				const { ok: auth_profile, err: err_auth_profile } = auth_profile_;
				const { ok: project, err: err_project } = project_;

				console.log('project: ', project);

				project_ref = project;
				projects_update.update_project(project);

				if ($actor_profile.loggedIn) {
					const username = get(auth_profile, 'username', 'x');

					isProjectOwner = username === project.username;

					console.log('isProjectOwner: ', isProjectOwner);
				}
			});
		} catch (error) {
			console.log('error projects: ', error);
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
		}
	}

	function handleToggleEditMode(e) {
		is_edit_active.set(get(e, 'detail', false));

		projects_update.deselect_snaps_from_project();
	}

	async function handleDeleteSnaps() {
		const snaps = get($project_store.project, 'snaps', []);

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
					id: project_ref.id,
					canister_id: project_ref.canister_id
				}
			);

			const { ok: project } = await $actor_project_main.actor.get_project(
				project_ref.id,
				project_ref.canister_id
			);

			projects_update.update_project(project);
		} else {
			// navigate_to_home_with_notification();
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

	function handleSnapCreateModalOpen() {
		modal_update.change_visibility('snap_creation');
	}
</script>

<svelte:head>
	<title>Project</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 relative ml-12 mr-12">
	<div class="col-start-1 col-end-13 row-start-1 row-end-auto">
		<PageNavigation navigationItems={$page_navigation.navigationItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- Modals -->
	{#if $modal_visible.snap_creation}
		<SnapCreationModal project_ref={$project_store.project} />
	{/if}
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<!-- Fetching Project -->
	{#if $project_store.isFetching === true}
		<!-- Fetching Project Info Header -->
		<div class="col-start-1 col-end-13 row-start-2 row-end-3 mt-2 mb-5">
			<ProjectInfo isFetching={true} />
		</div>

		<!-- Fetching Project Snaps -->
		<div
			class="hidden lg:grid col-start-1 col-end-13 grid-cols-4
			row-start-3 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
		>
			<SnapCard isLoadingSnap={true} snap={{ metrics: { views: 0, likes: 0 } }} />
		</div>
	{/if}

	<!-- Project -->
	{#if isEmpty($project_store.project) === false}
		<!-- Project Info Header -->
		<div class="relative col-start-1 col-end-13 row-start-2 row-end-auto">
			<ProjectInfo project={$project_store.project} on:saveToFavorites={handleAddToFavorites} />
		</div>

		<!-- ProjectsTabs & ProjectEditActionsBar -->
		<div
			class="col-start-1 col-end-13 items-center justify-between row-start-3 row-end-auto mt-12 mb-6"
		>
			<ProjectTabs
				selectedTabState={$projectTabsState}
				on:selectSnapsTab={(e) => projectTabsState.set(e.detail)}
				on:selectRecsTab={(e) => projectTabsState.set(e.detail)}
				on:selectChangesTab={(e) => projectTabsState.set(e.detail)}
			/>
			{#if $projectTabsState.isSnapsSelected && isProjectOwner}
				<ProjectEditActionsBar
					isEditActive={$is_edit_active}
					on:toggleEditMode={handleToggleEditMode}
					on:clickRemove={handleDeleteSnaps}
				/>
			{/if}
		</div>

		{#if $projectTabsState.isSnapsSelected}
			<!-- No Snaps Found -->
			{#if $project_store.project.snaps && $project_store.project.snaps.length === 0 && $project_store.isFetching === false}
				<div
					class="hidden lg:grid col-start-1 col-end-13 grid-cols-4 row-start-4 row-end-auto gap-x-6 gap-y-12"
				>
					{#if isProjectOwner}
						<SnapCardCreate on:clickSnapCardCreate={handleSnapCreateModalOpen} />
					{/if}
				</div>
			{/if}

			<!-- Snaps -->
			{#if $project_store.project.snaps && $project_store.project.snaps.length > 0}
				<div
					class="hidden lg:grid col-start-1 col-end-13 grid-cols-4 row-start-4 row-end-auto gap-x-6 gap-y-12 mb-16"
				>
					{#each $project_store.project.snaps as snap}
						<SnapCard {snap} isEditMode={$is_edit_active} on:clickCard={handleSnapPreview} />
					{/each}
					{#if isProjectOwner}
						<SnapCardCreate on:clickSnapCardCreate={handleSnapCreateModalOpen} />
					{/if}
				</div>
			{/if}
		{/if}
	{/if}
</main>
