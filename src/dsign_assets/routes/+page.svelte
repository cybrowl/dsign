<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import get from 'lodash/get';

	import Login from '../components/Login.svelte';
	import Notification from 'dsign-components/components/Notification.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProjectCard from 'dsign-components/components/ProjectCard.svelte';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { actor_explore, actor_favorite_main } from '$stores_ref/actors.js';
	import { auth_favorite_main } from '$stores_ref/auth_client';
	import { explore_store } from '$stores_ref/fetch_store.js';
	import { modal_visible } from '$stores_ref/modal';
	import { notification_visible, notification } from '$stores_ref/notification';
	import page_navigation_update, { page_navigation } from '$stores_ref/page_navigation';
	import { local_storage_profile } from '$stores_ref/local_storage';

	page_navigation_update.add_item({
		name: 'Profile',
		href: `${$local_storage_profile.username}`,
		isSelected: false
	});

	onMount(async () => {
		if ($notification.message.length === 0) {
			await auth_favorite_main();
		}

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

<main class="hidden lg:grid grid-cols-12 gap-y-2 relative">
	<div class="col-start-2 col-end-12 mb-8">
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
			class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-x-10 gap-y-20 mt-2 mb-24"
		>
			{#each $explore_store.projects as project}
				<ProjectCard {project} showOptionsPopover={false} on:clickProject={handleProjectClick} />
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
