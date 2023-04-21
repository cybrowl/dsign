<script>
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import get from 'lodash/get';

	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProfileBanner from 'dsign-components/components/ProfileBanner.svelte';
	import ProfileInfo from 'dsign-components/components/ProfileInfo.svelte';
	import ProfileTabs from 'dsign-components/components/ProfileTabs.svelte';
	import ProjectCard from 'dsign-components/components/ProjectCard.svelte';
	import ProjectCardCreate from 'dsign-components/components/ProjectCardCreate.svelte';
	import ProjectPublicEmpty from 'dsign-components/components/ProjectPublicEmpty.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCardFavoriteEmpty from 'dsign-components/components/SnapCardFavoriteEmpty.svelte';

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
		auth_profile,
		auth_project_main
	} from '$stores_ref/auth_client';
	import { profileTabsState } from '$stores_ref/page_state';
	import {
		favorite_store,
		project_store,
		project_store_fetching,
		projects_update
	} from '$stores_ref/fetch_store';
	import modal_update, { modal_visible } from '$stores_ref/modal';
	import { local_storage_projects, local_storage_favorites } from '$stores_ref/local_storage';
	import page_navigation_update, { page_navigation } from '$stores_ref/page_navigation';

	let project = {
		name: '',
		snaps: []
	};

	let isProfileOwner = false;
	let profile = {};
	let snap_preview = null;

	page_navigation_update.delete_all();

	project_store_fetching();

	onMount(async () => {
		await Promise.all([auth_assets_img_staging(), auth_profile(), auth_project_main()]);

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

					isProfileOwner = username === $page.params.username;
				}
			});

			Promise.all([
				$actor_favorite_main.actor.get_all_snaps([$page.params.username]),
				$actor_project_main.actor.get_all_projects([$page.params.username])
			]).then(async ([favorites, projects]) => {
				const { ok: all_favs, err: err_get_all_favs } = favorites;
				const { ok: all_projects, err: err_all_projects } = projects;

				if (all_favs) {
					favorite_store.set({ isFetching: false, snaps: [...all_favs] });
					local_storage_favorites.set({ all_favorites_count: all_favs.length || 1 });
				}

				if (err_get_all_favs) {
					favorite_store.set({ isFetching: false, snaps: [] });
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
		modal_update.set_visibility_false('snap_preview');

		profileTabsState.set({
			isProjectsSelected: true,
			isFavoritesSelected: false
		});
	});

	function openAccountSettingsModal() {
		if (isProfileOwner) {
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

	function handleSnapPreviewModalOpen(e) {
		const snap = e.detail;
		snap_preview = snap;

		modal_update.change_visibility('snap_preview');
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
</script>

<svelte:head>
	<title>Profile</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 relative">
	<div class="col-start-2 col-end-12 row-start-1 row-end-2">
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
	<div class="relative col-start-2 col-end-4 row-start-2 row-end-3">
		<ProfileInfo
			avatar={get(profile, 'avatar.url', '')}
			is_authenticated={isProfileOwner}
			username={get(profile, 'username', '')}
			on:editProfile={openAccountSettingsModal}
		/>
	</div>

	<!-- ProfileBanner -->
	<div class="col-start-4 col-end-12 row-start-2 row-end-3">
		<ProfileBanner
			is_authenticated={isProfileOwner}
			profile_banner_url={get(profile, 'banner.url', '')}
			on:profileBannerChange={handleProfileBannerChange}
		/>
	</div>

	<!-- ProfileTabs -->
	<div
		class="hidden lg:grid col-start-4 col-end-12 row-start-3 row-end-4 mt-16
			self-end justify-between items-center h-10"
	>
		<ProfileTabs
			profileTabsState={$profileTabsState}
			on:selectProjectsTab={(e) => profileTabsState.set(e.detail)}
			on:selectFavoritesTab={(e) => profileTabsState.set(e.detail)}
		/>
	</div>

	<!-- Projects -->
	{#if $profileTabsState.isProjectsSelected}
		<!-- Fetching Projects -->
		{#if $project_store.isFetching === true}
			<div
				class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
				row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				<ProjectCard isLoadingProject={true} />
			</div>
		{/if}

		<!-- No Projects Found -->
		{#if $project_store.projects.length === 0 && $project_store.isFetching === false}
			<div
				class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
				row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				{#if isProfileOwner}
					<ProjectCardCreate on:clickProjectCardCreate={handleProjectCreateModalOpen} />
				{:else}
					<ProjectPublicEmpty />
				{/if}
			</div>
		{/if}

		<!-- Project -->
		{#if $project_store.isFetching === false && $project_store.projects.length > 0}
			<div
				class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
			row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				{#each $project_store.projects as project}
					<ProjectCard
						{project}
						showOptionsPopover={isProfileOwner ? true : false}
						on:clickProject={handleProjectClick}
						on:clickRenameProject={handleProjectRenameModalOpen}
						on:clickDeleteProject={handleProjectDeleteModalOpen}
					/>
				{/each}
				{#if isProfileOwner}
					<ProjectCardCreate on:clickProjectCardCreate={handleProjectCreateModalOpen} />
				{/if}
			</div>
		{/if}
	{/if}

	<!-- Favorites -->
	{#if $profileTabsState.isFavoritesSelected}
		<!-- Fetching Snaps -->
		{#if $favorite_store.isFetching === true}
			<div
				class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
				row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				{#each { length: $local_storage_favorites.all_favorites_count } as _, i}
					<SnapCard isLoadingSnap={true} showMetricLikesNumber={false} />
				{/each}
			</div>
		{/if}

		<!-- No Snaps Found -->
		{#if $favorite_store.snaps.length === 0 && $favorite_store.isFetching === false}
			<div
				class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
				row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				<SnapCardFavoriteEmpty />
			</div>
		{/if}

		<!-- Snaps -->
		{#if $favorite_store.snaps.length > 0}
			<div
				class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
				row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				{#each $favorite_store.snaps as snap}
					<SnapCard
						{snap}
						showUsername={true}
						showMetricLikesNumber={false}
						on:clickCard={handleSnapPreviewModalOpen}
					/>
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
