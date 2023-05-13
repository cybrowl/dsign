<script>
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import get from 'lodash/get';

	import Login from '$components_ref/Login.svelte';
	import {
		FavoriteCardEmpty,
		PageNavigation,
		ProfileBanner,
		ProfileInfo,
		ProfileTabs,
		ProjectCard,
		ProjectCardCreate,
		ProjectCardEmpty
	} from 'dsign-components-v2';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import ProjectCreationModal from '$modals_ref/ProjectCreationModal.svelte';
	import ProjectDeleteModal from '$modals_ref/ProjectDeleteModal.svelte';
	import ProjectRenameModal from '$modals_ref/ProjectRenameModal.svelte';

	import {
		actor_assets_img_staging,
		actor_favorite_main,
		actor_profile,
		actor_project_main
	} from '$stores_ref/actors';
	import {
		auth_assets_img_staging,
		auth_favorite_main,
		auth_profile,
		auth_project_main
	} from '$stores_ref/auth_client';
	import { profileTabsState } from '$stores_ref/page_state';
	import {
		favorite_store,
		favorites_update,
		project_store_fetching,
		project_store,
		projects_update
	} from '$stores_ref/fetch_store';
	import modal_update, { modal_visible } from '$stores_ref/modal';
	import { local_storage_projects, local_storage_favorites } from '$stores_ref/local_storage';
	import page_navigation_update, { page_navigation } from '$stores_ref/page_navigation';

	let project = {
		name: '',
		snaps: []
	};

	let is_owner = false;
	let profile = {};

	page_navigation_update.delete_all();

	project_store_fetching();

	onMount(async () => {
		await Promise.all([
			auth_assets_img_staging(),
			auth_profile(),
			auth_project_main(),
			auth_favorite_main()
		]);

		try {
			Promise.all([
				$actor_profile.actor.get_profile(),
				$actor_profile.actor.get_profile_public($page.params.username)
			]).then(async ([auth_profile, public_profile]) => {
				const { ok: auth_profile_, err: err_auth_profile } = auth_profile;
				const { ok: public_profile_, err: err_public_profile } = public_profile;

				profile = public_profile_;

				if ($actor_profile.loggedIn) {
					const username = get(auth_profile_, 'username', 'x');

					is_owner = username === $page.params.username;
				}
			});

			Promise.all([
				$actor_favorite_main.actor.get_all_projects([$page.params.username]),
				$actor_project_main.actor.get_all_projects([$page.params.username])
			]).then(async ([favorites, projects]) => {
				const { ok: all_favs, err: err_get_all_favs } = favorites;
				const { ok: all_projects, err: err_all_projects } = projects;

				console.log('all_favs: ', all_favs);
				console.log('err_get_all_favs: ', err_get_all_favs);

				if (all_favs) {
					favorite_store.set({ isFetching: false, projects: [...all_favs] });
					local_storage_favorites.set({ all_favorites_count: all_favs.length || 1 });
				}

				if (err_get_all_favs) {
					favorite_store.set({ isFetching: false, projects: [] });
					local_storage_favorites.set({ all_favorites_count: 1 });

					if (err_get_all_favs['UserNotFound'] === true) {
						await $actor_favorite_main.actor.create_user_favorite_storage();
					}
				}

				if (all_projects) {
					project_store.set({ isFetching: false, projects: [...all_projects] });

					local_storage_projects.set({ all_projects_count: all_projects.length || 1 });
				} else {
					project_store.set({ isFetching: false, projects: [] });

					if (err_all_projects['UserNotFound'] === true) {
						await $actor_project_main.actor.create_user_project_storage();
					}
				}
			});
		} catch (error) {
			console.log('error projects: ', error);
			goto('/');
			console.log('error: call', error);
		}
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

		goto(`/project/${project.id}?canister_id=${project.canister_id}`);
	}

	async function handleProfileBannerChange(event) {
		let files = event.detail;

		if ($actor_assets_img_staging.loggedIn && $actor_profile.loggedIn) {
			const selectedFile = files[0];

			const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
			const create_asset_args = {
				data: [...imageAsUnit8ArrayBuffer],
				file_format: selectedFile.type
			};

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
		modal_update.change_visibility('project_creation');
	}

	function handleProjectRenameModalOpen(e) {
		modal_update.change_visibility('project_rename');

		project = get(e, 'detail');
	}

	async function handleProjectDeleteModalOpen(e) {
		modal_update.change_visibility('project_options');

		project = get(e, 'detail');
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

<main class="hidden lg:grid grid-cols-12 relative ml-12 mr-12">
	<div class="col-start-1 col-end-13 row-start-1 row-end-auto">
		<PageNavigation navigationItems={$page_navigation.navigationItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- Modals -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}
	{#if $modal_visible.project_creation}
		<ProjectCreationModal />
	{/if}
	{#if $modal_visible.project_options}
		<ProjectDeleteModal {project} />
	{/if}
	{#if $modal_visible.project_rename}
		<ProjectRenameModal {project} />
	{/if}

	<!-- ProfileInfo -->
	<div class="relative col-start-1 col-end-4 row-start-2 row-end-auto">
		<ProfileInfo
			avatar={get(profile, 'avatar.url', '')}
			{is_owner}
			username={get(profile, 'username', '')}
			on:editProfile={openAccountSettingsModal}
		/>
	</div>

	<!-- ProfileBanner -->
	<div class="col-start-4 col-end-13 row-start-2 row-end-auto">
		<ProfileBanner
			is_authenticated={is_owner}
			profile_banner_url={get(profile, 'banner.url', '')}
			on:profileBannerChange={handleProfileBannerChange}
		/>
	</div>

	<!-- ProfileTabs -->
	<div
		class="hidden lg:grid col-start-4 col-end-13 row-start-3 row-end-auto mt-12 self-end justify-between items-center mb-8"
	>
		<ProfileTabs
			profileTabsState={$profileTabsState}
			on:selectProjectsTab={(e) => profileTabsState.set(e.detail)}
			on:selectFavoritesTab={(e) => profileTabsState.set(e.detail)}
		/>
	</div>

	<!-- Projects -->
	{#if $profileTabsState.isProjectsSelected}
		<div
			class="hidden lg:grid col-start-4 col-end-13 grid-cols-3 row-start-4 row-end-auto gap-x-8 gap-y-12 mb-16"
		>
			<!-- Fetching Projects -->
			{#if $project_store.isFetching === true}
				<ProjectCard isLoadingProject={true} />
			{/if}

			<!-- No Projects Found -->
			{#if $project_store.isFetching === false && $project_store.projects.length === 0}
				{#if is_owner}
					<ProjectCardCreate on:clickProjectCardCreate={handleProjectCreateModalOpen} />
				{:else}
					<ProjectCardEmpty />
				{/if}
			{/if}

			<!-- Project -->
			{#if $project_store.isFetching === false && $project_store.projects.length > 0}
				{#each $project_store.projects as project}
					<ProjectCard
						{project}
						showOptionsPopover={is_owner ? true : false}
						on:clickProject={handleProjectClick}
						on:clickRenameProject={handleProjectRenameModalOpen}
						on:clickDeleteProject={handleProjectDeleteModalOpen}
					/>
				{/each}
				{#if is_owner}
					<ProjectCardCreate on:clickProjectCardCreate={handleProjectCreateModalOpen} />
				{/if}
			{/if}
		</div>
	{/if}

	<!-- Favorites -->
	{#if $profileTabsState.isFavoritesSelected}
		<div
			class="hidden lg:grid col-start-4 col-end-13 grid-cols-3 row-start-4 row-end-auto gap-x-8 gap-y-12 mb-16"
		>
			<!-- Fetching Favorites -->
			{#if $favorite_store.isFetching === true}
				<ProjectCard isLoadingProject={true} />
			{/if}

			<!-- No Favorites Found -->
			{#if $favorite_store.projects.length === 0 && $favorite_store.isFetching === false}
				<FavoriteCardEmpty />
			{/if}

			<!-- Favorites -->
			{#if $favorite_store.projects.length > 0}
				{#each $favorite_store.projects as project}
					<ProjectCard
						{project}
						hideSnapsCount={true}
						showUsername={true}
						showOptionsPopover={is_owner ? true : false}
						optionsPopoverHide={{
							rename: true,
							delete: false
						}}
						on:clickProject={handleProjectClick}
						on:clickDeleteProject={handleDeleteFavorite}
					/>
				{/each}
			{/if}
		</div>
	{/if}
</main>

<!-- Mobile Not Supported -->
<div class="grid lg:hidden h-screen place-items-center text-white text-4xl">
	<h1>Sorry, Mobile Not Supported</h1>
</div>
