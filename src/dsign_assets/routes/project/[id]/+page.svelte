<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import get from 'lodash/get';
	import last from 'lodash/last';
	import isEmpty from 'lodash/isEmpty';

	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProjectEditActionsBar from 'dsign-components/components/ProjectEditActionsBar.svelte';
	import ProjectInfoHeader from 'dsign-components/components/ProjectInfoHeader.svelte';
	import ProjectTabs from 'dsign-components/components/ProjectTabs.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCardCreate from 'dsign-components/components/SnapCardCreate.svelte';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import SnapCreationModal from '$modals_ref/SnapCreationModal.svelte';

	import { actor_project_main, actor_snap_main, actor_profile } from '$stores_ref/actors';
	import { project_store, project_store_fetching, projects_update } from '$stores_ref/fetch_store';
	import { auth_profile, auth_project_main, auth_snap_main } from '$stores_ref/auth_client';
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

	page_navigation_update.deselect_all();

	let isProjectOwner = false;
	let project_ref = {};

	if ($disable_project_store_reset === false) {
		project_store_fetching();
	} else {
		disable_project_store_reset.set(false);
	}

	onMount(async () => {
		await Promise.all([auth_profile(), auth_snap_main(), auth_project_main()]);

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

		snap_preview.set(snap);

		goto('/snap/' + snap.id + '?canister_id=' + snap.canister_id);
	}

	function handleSnapCreateModalOpen() {
		modal_update.change_visibility('snap_creation');
	}
</script>

<svelte:head>
	<title>Project</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12">
		<PageNavigation navigationItems={$page_navigation.navigationItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- Modals -->
	{#if $modal_visible.snap_creation}
		<SnapCreationModal {project_ref} />
	{/if}
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<!-- Fetching Project -->
	{#if $project_store.isFetching === true}
		<!-- Fetching Project Info Header -->
		<div class="col-start-2 col-end-12 row-start-2 row-end-3 mt-2 mb-5">
			<ProjectInfoHeader isFetching={true} />
		</div>

		<!-- Fetching Project Snaps -->
		<div
			class="hidden lg:grid col-start-2 col-end-12 grid-cols-4 
			row-start-3 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
		>
			<SnapCard isLoadingSnap={true} snap={{ metrics: { views: 0, likes: 0 } }} />
		</div>
	{/if}

	<!-- Project -->
	{#if isEmpty($project_store.project) === false}
		<!-- Project Info Header -->
		<div class="col-start-2 col-end-6 row-start-2 row-end-3 mb-5">
			<ProjectInfoHeader project={$project_store.project} />
		</div>

		<!-- ProjectsTabs & ProjectEditActionsBar -->
		<div class="col-start-2 col-end-12 row-start-3 row-end-4 mb-5">
			<ProjectTabs
				selectedTabState={$projectTabsState}
				on:selectSnapsTab={(e) => projectTabsState.set(e.detail)}
				on:selectIssuesTab={(e) => projectTabsState.set(e.detail)}
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
					class="hidden lg:grid col-start-2 col-end-12 grid-cols-4 
				row-start-4 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
				>
					{#if isProjectOwner}
						<SnapCardCreate on:clickSnapCardCreate={handleSnapCreateModalOpen} />
					{/if}
				</div>
			{/if}

			<!-- Snaps -->
			{#if $project_store.project.snaps && $project_store.project.snaps.length > 0}
				<div
					class="hidden lg:grid col-start-2 col-end-12 grid-cols-4 
				row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
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
