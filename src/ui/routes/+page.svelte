<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import get from 'lodash/get';

	import Login from '../components/Login.svelte';
	import { Notification, PageNavigation, ProjectCard } from 'dsign-components';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { actor_explore } from '$stores_ref/actors.js';
	import { disable_project_store_reset } from '$stores_ref/page_state';
	import { explore_store } from '$stores_ref/data_explore';
	import { modal_visible } from '$stores_ref/modal';
	import { notification_visible, notification } from '$stores_ref/notification';
	import { page_navigation } from '$stores_ref/page_navigation';
	import { init_auth } from '$stores_ref/auth_client';

	disable_project_store_reset.set(true);

	onMount(async () => {
		try {
			await init_auth();

			const projects = await $actor_explore.actor.get_all_projects();

			if (projects) {
				explore_store.set({ isFetching: false, projects });
			}
		} catch (error) {
			console.error('error: call', error);
		}
	});

	function goto_project(e) {
		let project = get(e, 'detail');

		// projects_update.update_project(project);

		goto(`/project/${project.name}?id=${project.id}&cid=${project.canister_id}`);
	}

	function goto_username(e) {
		let project = get(e, 'detail');

		// projects_update.update_project(project);

		goto(`/${project.username}`);
	}
</script>

<!-- Explore -->
<svelte:head>
	<title>DSign</title>
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

	<!-- Notification -->
	{#if $notification_visible.auth_error}
		<div class="notification_layout">
			<Notification is_visible={$notification_visible.auth_error} hide_delay_sec={2000}>
				<p>{$notification.message}</p>
			</Notification>
		</div>
	{/if}

	<!-- Projects -->
	{#if $explore_store.projects.length > 0}
		<div class="projects_layout">
			{#each $explore_store.projects as project (project.id)}
				<ProjectCard
					{project}
					hideSnapsCount={true}
					showUsername={true}
					showOptionsPopover={false}
					on:clickProject={goto_project}
					on:clickUsername={goto_username}
				/>
			{/each}
		</div>
	{/if}
</main>

<!-- Mobile Not Supported -->
{#if $explore_store.projects.length > 0}
	<div class="not_supported">
		<h1>Sorry, Mobile</h1>
		<h1>Coming Soon</h1>
	</div>
{/if}

<style lang="postcss">
	.grid_layout {
		@apply hidden lg:grid grid-cols-12 gap-y-2 relative mx-12 2xl:mx-60;
	}
	.navigation_main_layout {
		@apply row-start-1 row-end-auto col-start-1 col-end-13;
	}
	.notification_layout {
		@apply row-start-2 row-end-3 absolute col-start-12 col-end-13 top-0 right-0;
	}
	.projects_layout {
		@apply row-start-2 row-end-auto hidden lg:grid col-start-1 grid-cols-4 col-end-13 gap-x-6 gap-y-12 mb-16;
	}
	.not_supported {
		@apply lg:hidden flex flex-col items-center justify-center w-screen h-screen text-white text-4xl;
	}
</style>
