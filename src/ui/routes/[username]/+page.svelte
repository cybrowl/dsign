<script>
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { get } from 'lodash';

	import Login from '$components_ref/Login.svelte';
	import {
		CardEmpty,
		PageNavigation,
		ProfileBanner,
		ProfileInfo,
		ProfileTabs,
		ProjectCard,
		ProjectCardCreate
	} from 'dsign-components';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import ProjectUpsertModal from '$modals_ref/ProjectUpsertModal.svelte';
	import ProjectDeleteModal from '$modals_ref/ProjectDeleteModal.svelte';

	import {
		actor_assets_img_staging,
		actor_favorite_main,
		actor_profile,
		actor_project_main,
		actor_creator,
		actor_username_registry
	} from '$stores_ref/actors';
	import { auth, init_auth } from '$stores_ref/auth_client';
	import { profileTabsState, disable_project_store_reset } from '$stores_ref/page_state';
	import {
		favorite_store_fetching,
		favorite_store,
		favorites_update,
		project_store_fetching,
		project_store,
		projects_update
	} from '$stores_ref/fetch_store';
	import modal_update, { modal_visible, modal_mode } from '$stores_ref/modal';
	import { local_storage_projects, local_storage_favorites } from '$stores_ref/local_storage';
	import { page_navigation } from '$stores_ref/page_navigation';

	let project = {
		name: '',
		snaps: []
	};

	let profile = {};

	disable_project_store_reset.set(true);

	project_store_fetching();
	favorite_store_fetching();

	async function get_profile() {
		try {
			await auth.username_registry();
			const { ok: username_info } = await $actor_username_registry.actor.get_info_by_username(
				$page.params.username
			);

			await auth.creator(username_info.canister_id);
			const { ok: profile_res, err: err_profile } =
				await $actor_creator.actor.get_profile_by_username($page.params.username);

			profile = profile_res;

			console.log('profile_res: ', profile_res);

			const projects = profile_res.projects || [];
			const favorites = profile_res.favorites || [];

			project_store.set({ isFetching: false, projects: [...projects] });
			local_storage_projects.set({ all_projects_count: projects.length || 1 });

			favorite_store.set({ isFetching: false, projects: [...favorites] });
			local_storage_favorites.set({ all_favorites_count: favorites.length || 1 });
		} catch (error) {
			console.log('error call profile: ', error);
		}
	}

	$: if (profile.username && profile.username !== $page.params.username) {
		project_store_fetching();
		get_profile();
	}

	onMount(async () => {
		await init_auth();

		await get_profile();
	});

	onDestroy(() => {
		projects_update.update_projects([]);

		profileTabsState.set({
			isProjectsSelected: true,
			isFavoritesSelected: false
		});
	});

	function openAccountSettingsModal() {
		if (is_owner) {
			modal_update.change_visibility('account_settings');
		}
	}

	function handleProjectClick(e) {
		project = get(e, 'detail');

		projects_update.update_project(project);

		goto(`/project/${project.id}?canister_id=${project.canister_id}`);
	}

	async function handleProfileBannerChange(event) {
		let file = event.detail;

		if ($actor_assets_img_staging.loggedIn && $actor_profile.loggedIn) {
			const selectedFile = file;

			const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
			const create_asset_args = {
				data: [...imageAsUnit8ArrayBuffer],
				file_format: selectedFile.type
			};

			console.log('create_asset_args: ', create_asset_args);

			try {
				let img_asset_id = await $actor_assets_img_staging.actor.create_asset(create_asset_args);
				const { ok: update_profie, err: err_update_profile_banner } =
					await $actor_profile.actor.update_profile_banner([img_asset_id]);

				let { ok: profile_ } = await $actor_profile.actor.get_profile();

				const randomNumber = Math.floor(Math.random() * 1000);
				profile = profile_;
				profile.banner.url = profile_.banner.url + '&' + randomNumber;
			} catch (error) {
				console.log('error', error);
			}
		}
	}

	function handleProjectCreateModalOpen() {
		modal_update.change_visibility('project_upsert');
		modal_mode.set({ project_create: true });
	}

	function handleProjectEditModalOpen(e) {
		project = get(e, 'detail');

		modal_update.change_visibility('project_upsert');
		modal_mode.set({ project_create: false, project });
	}

	async function handleProjectDeleteModalOpen(e) {
		project = get(e, 'detail');
		modal_update.change_visibility('project_delete');
	}

	async function handleDeleteFavorite(e) {
		const selected_project = get(e, 'detail');
		const project_ref = {
			id: selected_project.id,
			canister_id: selected_project.canister_id
		};

		if ($actor_favorite_main.loggedIn) {
			try {
				favorites_update.delete_favorite(project_ref);

				await $actor_favorite_main.actor.delete_project(project_ref);
			} catch (error) {
				console.log('error: call', error);
			}
		}
	}
</script>

<svelte:head>
	<title>Profile</title>
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

	<!-- ProjectUpsertModal -->
	{#if $modal_visible.project_upsert}
		<ProjectUpsertModal />
	{/if}

	<!-- ProjectDeleteModal -->
	{#if $modal_visible.project_delete}
		<ProjectDeleteModal {project} />
	{/if}

	<!-- ProfileInfo -->
	<div class="profile_info_layout">
		<ProfileInfo
			avatar={get(profile, 'avatar.url', '')}
			is_owner={profile.is_owner}
			username={get(profile, 'username', '')}
			on:editProfile={openAccountSettingsModal}
		/>
	</div>

	<!-- ProfileBanner -->
	<div class="profile_banner_layout">
		<ProfileBanner
			is_owner={profile.is_owner}
			profile_banner_url={get(profile, 'banner.url', '')}
			on:profileBannerChange={handleProfileBannerChange}
		/>
	</div>

	<!-- ProfileTabs -->
	<div class="tabs_layout">
		<ProfileTabs
			profileTabsState={$profileTabsState}
			on:selectProjectsTab={(e) => profileTabsState.set(e.detail)}
			on:selectFavoritesTab={(e) => profileTabsState.set(e.detail)}
		/>
	</div>

	<div class="content_layout">
		<!-- Projects -->
		{#if $profileTabsState.isProjectsSelected}
			<!-- Fetching Projects -->
			{#each { length: 1 } as _, i}
				{#if $project_store.isFetching === true}
					<ProjectCard isLoadingProject={true} />
				{/if}
			{/each}

			<!-- No Projects Found -->
			{#if $project_store.isFetching === false && $project_store.projects.length === 0}
				{#if profile.is_owner}
					<ProjectCardCreate on:createProject={handleProjectCreateModalOpen} />
				{:else}
					<CardEmpty
						name="project_empty"
						content="No projects found"
						view_size={{ width: '92', height: '92' }}
					/>
				{/if}
			{/if}

			<!-- Project -->
			{#if $project_store.isFetching === false && $project_store.projects.length > 0}
				{#each $project_store.projects as project}
					<ProjectCard
						{project}
						showOptionsPopover={profile.is_owner ? true : false}
						optionsPopover={{ edit: true, delete: true }}
						on:clickProject={handleProjectClick}
						on:editProject={handleProjectEditModalOpen}
						on:deleteProject={handleProjectDeleteModalOpen}
					/>
				{/each}
				{#if profile.is_owner}
					<ProjectCardCreate on:createProject={handleProjectCreateModalOpen} />
				{/if}
			{/if}
		{/if}

		<!-- Favorites -->
		{#if $profileTabsState.isFavoritesSelected}
			<!-- Fetching Favorites -->
			{#each { length: $local_storage_favorites.all_favorites_count } as _, i}
				{#if $favorite_store.isFetching === true}
					<ProjectCard isLoadingProject={true} />
				{/if}
			{/each}

			<!-- No Favorites Found -->
			{#if $favorite_store.projects.length === 0 && $favorite_store.isFetching === false}
				<CardEmpty
					name="project_empty"
					content="No favorite projects"
					view_size={{ width: '92', height: '92' }}
				/>
			{/if}

			<!-- Favorites -->
			{#if $favorite_store.projects.length > 0}
				{#each $favorite_store.projects as project}
					<ProjectCard
						{project}
						hideSnapsCount={true}
						showUsername={true}
						showOptionsPopover={profile.is_owner ? true : false}
						optionsPopover={{
							edit: false,
							delete: true
						}}
						on:clickProject={handleProjectClick}
						on:deleteProject={handleDeleteFavorite}
					/>
				{/each}
			{/if}
		{/if}
	</div>
</main>

<!-- Mobile Not Supported -->
<div class="not_supported">
	<h1>Sorry, Mobile Not Supported</h1>
</div>

<style lang="postcss">
	.grid_layout {
		@apply hidden lg:grid grid-cols-12 relative mx-12 2xl:mx-60;
	}
	.navigation_main_layout {
		@apply row-start-1 row-end-auto col-start-1 col-end-13;
	}
	.profile_info_layout {
		@apply row-start-2 row-end-auto relative col-start-1 col-end-4;
	}
	.profile_banner_layout {
		@apply row-start-2 row-end-auto col-start-4 col-end-13;
	}
	.tabs_layout {
		@apply row-start-3 row-end-auto hidden lg:grid col-start-4 col-end-13 mt-12 self-end justify-between items-center mb-8;
	}
	.content_layout {
		@apply row-start-4 row-end-auto hidden lg:grid grid-cols-3 col-start-4 col-end-13  gap-x-8 gap-y-12 mb-16;
	}
	.not_supported {
		@apply grid lg:hidden h-screen place-items-center text-white text-4xl;
	}
</style>
