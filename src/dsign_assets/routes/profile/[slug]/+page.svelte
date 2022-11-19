<!-- src/routes/profile.svelte -->
<script>
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { AuthClient } from '@dfinity/auth-client';
	import get from 'lodash/get';

	// components
	import AccountCreationModal from '$modals_ref/AccountCreationModal.svelte';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProfileBanner from 'dsign-components/components/ProfileBanner.svelte';
	import ProfileInfo from 'dsign-components/components/ProfileInfo.svelte';
	import ProfileTabs from 'dsign-components/components/ProfileTabs.svelte';
	import ProjectCard from 'dsign-components/components/ProjectCard.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCreationModal from '$modals_ref/SnapCreationModal.svelte';

	// stores
	import { actor_profile, actor_project_main } from '$stores_ref/actors';
	import { project_store } from '$stores_ref/fetch_store';

	import { local_storage_profile } from '$stores_ref/local_storage';
	import { modal_visible } from '$stores_ref/modal';
	import modal_update from '$stores_ref/modal_update';
	import { page_navigation } from '$stores_ref/page_navigation';
	import page_navigation_update from '$stores_ref/page_navigation_update';
	import { profile_tabs } from '$stores_ref/page_state';

	// variables
	let isAuthenticated = false;
	let project = {
		name: ''
	};
	let isProfileOwner = false;
	let profile_info = {
		profile: {
			avatar: {
				url: ''
			},
			username: ''
		},
		projects: []
	};

	// execution
	page_navigation_update.select_item(3);

	onMount(async () => {
		let authClient = await AuthClient.create();

		isAuthenticated = await authClient.isAuthenticated();

		try {
			if (isAuthenticated) {
				Promise.all([
					$actor_profile.actor.get_profile(),
					$actor_profile.actor.get_profile_public($page.params.slug)
				]).then(([profile_owner, profile_public]) => {
					const { ok: profile_owner_ } = profile_owner;
					const { ok: profile_public_ } = profile_public;

					isProfileOwner = profile_owner_.username === $page.params.slug;
					profile_info.profile = profile_public_;
				});

				const { ok: all_projects, err: err_all_projects } =
					await $actor_project_main.actor.get_all_projects([$page.params.slug]);

				if (all_projects) {
					project_store.set({ isFetching: false, projects: [...all_projects] });
				}
			}
		} catch (error) {
			// Show error notification
			// TODO: log error
		}
	});

	onDestroy(() => {
		project_store.set({ isFetching: true, projects: [] });
		profile_tabs.set({
			isProjectsSelected: true,
			isProjectSelected: false
		});
	});

	function openAccountSettingsModal() {
		if (isProfileOwner) {
			modal_update.change_visibility('account_settings');
		}
	}

	function handleProjectClick(e) {
		project = get(e, 'detail');

		project.name = project.name.charAt(0).toUpperCase() + project.name.slice(1);

		profile_tabs.set({
			isProjectsSelected: false,
			isProjectSelected: true
		});
	}
</script>

<svelte:head>
	<title>Profile</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 relative">
	<div class="col-start-2 col-end-12 row-start-1 row-end-2">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<!-- AccountCreationModal -->
	{#if $modal_visible.account_creation}
		<AccountCreationModal />
	{/if}

	<!-- SnapCreationModal -->
	{#if $modal_visible.snap_creation}
		<SnapCreationModal />
	{/if}

	<!-- ProfileInfo -->
	<div class="relative col-start-2 col-end-4 row-start-2 row-end-3">
		<ProfileInfo
			avatar={get(profile_info, 'profile.avatar.url', '')}
			is_authenticated={isProfileOwner}
			username={get(profile_info, 'profile.username', '')}
			on:editProfile={openAccountSettingsModal}
		/>
	</div>

	<!-- ProfileBanner -->
	<div class="col-start-4 col-end-12 row-start-2 row-end-3">
		<ProfileBanner
			is_authenticated={isProfileOwner}
			profile_banner_url="/default_profile_banner.png"
		/>
	</div>

	<!-- ProfileTabs -->
	<div
		class="hidden lg:grid col-start-4 col-end-12 row-start-3 row-end-4 mt-16
			self-end justify-between items-center h-10"
	>
		<ProfileTabs
			project_name={project.name}
			profileTabs={$profile_tabs}
			on:toggleProjects={(e) => profile_tabs.set(e.detail)}
		/>
	</div>

	<!-- Projects -->
	{#if $profile_tabs.isProjectsSelected}
		<div
			class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
			row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
		>
			{#each $project_store.projects as project}
				<ProjectCard {project} on:clickProject={handleProjectClick} />
			{/each}
		</div>
	{/if}

	<!-- Project -->
	{#if $profile_tabs.isProjectSelected}
		<!-- Snaps -->
		{#if project.snaps && project.snaps.length > 0}
			<div
				class="col-start-4 col-end-12 grid grid-cols-4 
						row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				{#each project.snaps as snap}
					<SnapCard {snap} />
				{/each}
			</div>
		{/if}
	{/if}
</main>

<!-- Mobile Not Supported -->
<div class="grid lg:hidden h-screen place-items-center text-white text-4xl">
	<h1>Sorry, Mobile Not Supported</h1>
</div>

<style>
</style>
