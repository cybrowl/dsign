<script>
	import { page } from '$app/stores';
	import { onDestroy, onMount } from 'svelte';
	import get from 'lodash/get';
	import last from 'lodash/last';
	import isEmpty from 'lodash/isEmpty';

	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProjectInfoHeader from 'dsign-components/components/ProjectInfoHeader.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';

	import SnapPreviewModal from '$modals_ref/SnapPreviewModal.svelte';

	import { actor_project_main } from '$stores_ref/actors';
	import { profile_tabs } from '$stores_ref/page_state';
	import {
		project_store_public,
		project_store_public_fetching,
		projects_update
	} from '$stores_ref/fetch_store';
	import modal_update, { modal_visible } from '$stores_ref/modal';
	import page_navigation_update, { page_navigation } from '$stores_ref/page_navigation';

	let snap_preview = null;

	page_navigation_update.deselect_all();

	isEmpty($project_store_public.project) === true && project_store_public_fetching();

	onMount(async () => {
		const canister_id = $page.url.searchParams.get('canister_id');
		const project_id = last(get($page, 'url.pathname', '').split('/'));

		try {
			const { ok: project } = await $actor_project_main.actor.get_project(project_id, canister_id);

			console.log('project: ', project);

			projects_update.update_project_public(project);
		} catch (error) {
			console.log('error projects: ', error);
		}
	});

	onDestroy(() => {
		projects_update.update_project_public([]);
		profile_tabs.set({
			isProjectsSelected: true,
			isProjectSelected: false
		});
	});

	function handleSnapPreviewModalOpen(e) {
		const snap = e.detail;
		snap_preview = snap;

		modal_update.change_visibility('snap_preview');
	}
</script>

<svelte:head>
	<title>Project</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-8">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- SnapPreviewModal -->
	{#if $modal_visible.snap_preview && snap_preview}
		<SnapPreviewModal snap={snap_preview} />
	{/if}

	<!-- Fetching Project -->
	{#if $project_store_public.isFetching === true}
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
	{#if isEmpty($project_store_public.project) === false}
		<!-- Project Info Header -->
		<div class="col-start-2 col-end-6 row-start-2 row-end-3 mb-5">
			<ProjectInfoHeader project={$project_store_public.project} />
		</div>

		<!-- Snaps -->
		{#if $project_store_public.project.snaps && $project_store_public.project.snaps.length > 0}
			<div
				class="hidden lg:grid col-start-2 col-end-12 grid-cols-4 
				row-start-3 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				{#each $project_store_public.project.snaps as snap}
					<SnapCard {snap} on:clickCard={handleSnapPreviewModalOpen} />
				{/each}
			</div>
		{/if}
	{/if}
</main>
