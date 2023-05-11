<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import get from 'lodash/get';

	import Login from '../components/Login.svelte';
	import Notification from 'dsign-components/components/Notification.svelte';
	// import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	// import ProjectCard from 'dsign-components/components/ProjectCard.svelte';
	import { PageNavigation, ProjectCard } from 'dsign-components-v2';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { actor_explore } from '$stores_ref/actors.js';
	import { explore_store } from '$stores_ref/fetch_store.js';
	import { modal_visible } from '$stores_ref/modal';
	import { notification_visible, notification } from '$stores_ref/notification';
	import { page_navigation } from '$stores_ref/page_navigation';

	onMount(async () => {
		try {
			const all_projects = await $actor_explore.actor.get_all_projects();

			console.log('all_projects: ', all_projects);

			if (all_projects) {
				explore_store.set({ isFetching: false, projects: [...all_projects] });
			}
		} catch (error) {
			console.error('error: call', error);
		}
	});

	function handleProjectClick(e) {
		let project = get(e, 'detail');

		goto(`/project/${project.id}?canister_id=${project.canister_id}`);
	}
</script>

<!-- Explore -->
<svelte:head>
	<title>DSign</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 relative ml-12 mr-12">
	<div class="col-start-1 col-end-13 row-start-1 row-end-auto">
		<PageNavigation navigationItems={$page_navigation.navigationItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<!-- Notification -->
	{#if $notification_visible.auth_error}
		<div class="absolute col-start-9 col-end-12 row-start-1 row-end-2 bottom-0 right-0">
			<Notification is_visible={$notification_visible.auth_error} hide_delay_sec={2000}>
				<p>{$notification.message}</p>
			</Notification>
		</div>
	{/if}

	<!-- Projects -->
	{#if $explore_store.projects.length > 0}
		<div
			class="hidden lg:grid col-start-1 col-end-13 grid-cols-4 row-start-2 row-end-auto gap-x-6 gap-y-12 mb-16"
		>
			{#each $explore_store.projects as project}
				<ProjectCard
					{project}
					hideSnapsCount={true}
					showUsername={true}
					showOptionsPopover={false}
					on:clickProject={handleProjectClick}
				/>
			{/each}
		</div>
	{/if}
</main>

<!-- Mobile Not Supported -->
<div class="grid lg:hidden h-screen place-items-center text-white text-4xl">
	<h1>Sorry, Mobile Not Supported</h1>
</div>

<style>
</style>
