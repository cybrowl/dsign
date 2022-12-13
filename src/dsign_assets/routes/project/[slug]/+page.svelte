<script>
	import { page } from '$app/stores';
	import { onDestroy, onMount } from 'svelte';
	import get from 'lodash/get';
	import last from 'lodash/last';

	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';

	import { actor_project_main } from '$stores_ref/actors';
	import { profile_tabs } from '$stores_ref/page_state';
	import { project_store_public, projects_update } from '$stores_ref/fetch_store';
	import page_navigation_update, { page_navigation } from '$stores_ref/page_navigation';

	page_navigation_update.deselect_all();

	onMount(async () => {
		const canister_id = $page.url.searchParams.get('canister_id');
		const project_id = last(get($page, 'url.pathname', '').split('/'));

		try {
			const { ok: project } = await $actor_project_main.actor.get_project(project_id, canister_id);

			projects_update.update_project_public(project);
		} catch (error) {
			console.log('error projects: ', error);
		}
	});

	onDestroy(() => {
		projects_update.update_projects_public([]);
		profile_tabs.set({
			isProjectsSelected: true,
			isProjectSelected: false
		});
	});
</script>

<svelte:head>
	<title>Project</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-24">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- Project -->
	{#if Object.keys($project_store_public.project).length > 0}
		<!-- Snaps -->
		{#if $project_store_public.project.snaps && $project_store_public.project.snaps.length > 0}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-2 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				{#each $project_store_public.project.snaps as snap}
					<SnapCard {snap} />
				{/each}
			</div>
		{/if}
	{/if}
</main>
