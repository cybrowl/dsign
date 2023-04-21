<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import get from 'lodash/get';
	import last from 'lodash/last';
	import isEmpty from 'lodash/isEmpty';

	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProjectInfoHeader from 'dsign-components/components/ProjectInfoHeader.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCardCreate from 'dsign-components/components/SnapCardCreate.svelte';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import SnapCreationModal from '$modals_ref/SnapCreationModal.svelte';
	import SnapPreviewModal from '$modals_ref/SnapPreviewModal.svelte';

	import { actor_project_main, actor_profile } from '$stores_ref/actors';
	import { project_store, project_store_fetching, projects_update } from '$stores_ref/fetch_store';
	import { auth_profile } from '$stores_ref/auth_client';
	import modal_update, { modal_visible } from '$stores_ref/modal';
	import page_navigation_update, {
		snap_preview,
		page_navigation
	} from '$stores_ref/page_navigation';
	import { disable_project_store_reset } from '$stores_ref/page_state';

	page_navigation_update.deselect_all();

	let isProjectOwner = false;
	let project_ref = {};

	if ($disable_project_store_reset === false) {
		project_store_fetching();
	} else {
		disable_project_store_reset.set(false);
	}

	onMount(async () => {
		await Promise.all([auth_profile()]);

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

					console.log('isProjectOwner: ', isProjectOwner);
					isProjectOwner = username === project.username;
				}
			});
		} catch (error) {
			console.log('error projects: ', error);
		}
	});

	function handleSnapPreviewModalOpen(e) {
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
	<div class="col-start-2 col-end-12 mb-8">
		<PageNavigation navigationItems={$page_navigation.navigationItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- Modals -->
	{#if $modal_visible.snap_creation}
		<SnapCreationModal {project_ref} />
	{/if}
	{#if $modal_visible.snap_preview && snap_preview}
		<SnapPreviewModal snap={snap_preview} />
	{/if}
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}
	{#if $modal_visible.snap_preview && snap_preview}
		<SnapPreviewModal snap={snap_preview} />
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

		<!-- No Snaps Found -->
		{#if $project_store.project.snaps && $project_store.project.snaps.length === 0 && $project_store.isFetching === false}
			<div
				class="hidden lg:grid col-start-2 col-end-12 grid-cols-4 
				row-start-3 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
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
				row-start-3 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				{#each $project_store.project.snaps as snap}
					<SnapCard {snap} on:clickCard={handleSnapPreviewModalOpen} />
				{/each}
				{#if isProjectOwner}
					<SnapCardCreate on:clickSnapCardCreate={handleSnapCreateModalOpen} />
				{/if}
			</div>
		{/if}
	{/if}
</main>
