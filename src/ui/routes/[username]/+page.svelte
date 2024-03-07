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

	import { FileStorage } from '$utils/file_storage';

	import { auth, init_auth } from '$stores_ref/auth_client';
	import {
		actor_creator,
		actor_file_scaling_manager,
		actor_file_storage,
		actor_username_registry
	} from '$stores_ref/actors';
	import { profile_store, profile_actions } from '$stores_ref/data_profile';

	import { profileTabsState, disable_project_store_reset } from '$stores_ref/page_state';
	import modal_update, { modal_visible, modal_mode } from '$stores_ref/modal';
	import { page_navigation } from '$stores_ref/page_navigation';
	import { ls_my_profile } from '$stores_ref/local_storage';

	profile_actions.fetching();

	let project = {};

	// $: if (profile.username && profile.username !== $page.params.username) {
	// 	profile_store_fetching();
	// 	get_profile();
	// }

	onMount(async () => {
		await init_auth();

		await get_profile();
	});

	onDestroy(() => {
		//TODO: reset profile_store

		profileTabsState.set({
			isProjectsSelected: true,
			isFavoritesSelected: false
		});
	});

	// ------------------------- Nav -------------------------
	function go_to_project(e) {
		project = get(e, 'detail');

		projects_update.update_project(project);

		goto(`/project/${project.id}?canister_id=${project.canister_id}`);
	}

	// ------------------------- Modals -------------------------
	function modal_open_account_settings() {
		if (get($ls_my_profile, 'is_owner', '')) {
			modal_update.change_visibility('account_settings');
		}
	}

	function modal_open_project_create() {
		modal_update.change_visibility('project_upsert');
		modal_mode.set({ project_create: true });
	}

	function modal_open_project_edit(e) {
		project = get(e, 'detail');

		modal_update.change_visibility('project_upsert');
		modal_mode.set({ project_create: false, project });
	}

	async function modal_open_project_delete(e) {
		project = get(e, 'detail');
		modal_update.change_visibility('project_delete');
	}

	// ------------------------- API -------------------------
	async function get_profile() {
		try {
			await auth.username_registry();
			const { ok: username_info } = await $actor_username_registry.actor.get_info_by_username(
				$page.params.username
			);

			await auth.creator(username_info.canister_id);
			const { ok: profile, err: err_profile } = await $actor_creator.actor.get_profile_by_username(
				$page.params.username
			);

			// TODO: if there is an err
			profile_store.set({ isFetching: false, profile: profile });
		} catch (error) {
			// TODO: log somwhere & error message
			console.log('error call profile: ', error);
		}
	}

	async function update_profile_banner(event) {
		let file = event.detail;

		const file_unit8 = new Uint8Array(await file.arrayBuffer());

		//TODO: rename to say something about storage canister id and about it being empty
		const storage_canister_id_alloc =
			await $actor_file_scaling_manager.actor.get_current_canister_id();

		await auth.creator(get($ls_my_profile, 'canister_id', ''));
		await auth.file_storage(storage_canister_id_alloc);

		const file_storage = new FileStorage($actor_file_storage.actor);

		const { ok: file_public } = await file_storage.store(file_unit8, {
			filename: file.name,
			content_type: file.type
		});

		const banner_file = {
			id: file_public.id,
			canister_id: file_public.canister_id,
			url: file_public.url
		};

		profile_actions.update_profile_banner(banner_file);

		const { ok: url, err: err_banner_update } =
			await $actor_creator.actor.update_profile_banner(banner_file);

		ls_my_profile.update((values) => {
			return {
				...values,
				banner: banner_file
			};
		});
	}

	async function delete_project_from_favs(e) {
		const selected_project = get(e, 'detail');

		//TODO: delete project from favs
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
			avatar={get($profile_store.profile, 'avatar.url', '')}
			is_owner={get($profile_store.profile, 'is_owner', '')}
			username={get($profile_store.profile, 'username', '')}
			on:editProfile={modal_open_account_settings}
		/>
	</div>

	<!-- ProfileBanner -->
	<div class="profile_banner_layout">
		<ProfileBanner
			is_owner={get($profile_store.profile, 'is_owner', '')}
			profile_banner_url={get($profile_store.profile, 'banner.url', '')}
			on:profileBannerChange={update_profile_banner}
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
				{#if $profile_store.isFetching === true}
					<ProjectCard isLoadingProject={true} />
				{/if}
			{/each}

			{#if $profile_store.isFetching === false}
				<!-- No Projects Found -->
				{#if $profile_store.profile.projects.length === 0}
					{#if $profile_store.profile.is_owner}
						<ProjectCardCreate on:createProject={modal_open_project_create} />
					{:else}
						<CardEmpty
							name="project_empty"
							content="No projects found"
							view_size={{ width: '92', height: '92' }}
						/>
					{/if}
				{/if}

				<!-- Projects -->
				{#if $profile_store.profile.projects.length > 0}
					{#each $profile_store.profile.projects as project}
						<ProjectCard
							{project}
							showOptionsPopover={$profile_store.profile.is_owner ? true : false}
							optionsPopover={{ edit: true, delete: true }}
							on:clickProject={go_to_project}
							on:editProject={modal_open_project_edit}
							on:deleteProject={modal_open_project_delete}
						/>
					{/each}
					{#if $profile_store.profile.is_owner}
						<ProjectCardCreate on:createProject={modal_open_project_create} />
					{/if}
				{/if}
			{/if}
		{/if}

		<!-- Favorites -->
		{#if $profileTabsState.isFavoritesSelected}
			<!-- Fetching Favorites -->
			{#each { length: 1 } as _, i}
				{#if $profile_store.isFetching === true}
					<ProjectCard isLoadingProject={true} />
				{/if}
			{/each}

			<!-- No Favorites Found -->
			{#if $profile_store.profile.favorites.length === 0 && $profile_store.profile.isFetching === false}
				<CardEmpty
					name="project_empty"
					content="No favorite projects"
					view_size={{ width: '92', height: '92' }}
				/>
			{/if}

			<!-- Favorites -->
			{#if $profile_store.profile.favorites > 0}
				{#each $profile_store.profile.favorites as project}
					<ProjectCard
						{project}
						hideSnapsCount={true}
						showUsername={true}
						showOptionsPopover={$profile_store.profile.is_owner ? true : false}
						optionsPopover={{
							edit: false,
							delete: true
						}}
						on:clickProject={go_to_project}
						on:deleteProject={delete_project_from_favs}
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
