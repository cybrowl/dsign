<script>
	import { onDestroy, onMount } from 'svelte';
	import { AuthClient } from '@dfinity/auth-client';
	import get from 'lodash/get.js';

	import Login from '../../components/Login.svelte';
	import Notification from 'dsign-components/components/Notification.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProjectEditActionsBar from 'dsign-components/components/ProjectEditActionsBar.svelte';
	import ProjectsTabs from 'dsign-components/components/ProjectsTabs.svelte';
	import ProjectCard from 'dsign-components/components/ProjectCard.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCardEmpty from 'dsign-components/components/SnapCardEmpty.svelte';

	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../modals/AccountSettingsModal.svelte';
	import SnapsMoveModal from '../../modals/SnapsMoveModal.svelte';
	import ProjectCreationModal from '../../modals/ProjectCreationModal.svelte';
	import ProjectOptionsDeleteModal from '../../modals/ProjectOptionsDeleteModal.svelte';
	import ProjectRenameModal from '../../modals/ProjectRenameModal.svelte';
	import SnapCreationModal from '../../modals/SnapCreationModal.svelte';

	// actors
	import { actor_project_main, actor_snap_main } from '../../store/actors';

	// local storage
	import { local_storage_snaps, local_storage_projects } from '../../store/local_storage';

	import { modal_visible } from '../../store/modal';
	import { notification_visible, notification } from '../../store/notification';
	import { page_navigation } from '../../store/page_navigation';
	import { project_store, snap_store } from '../../store/fetch_store';
	import { projects_tabs, is_edit_active } from '../../store/page_state';

	let isAuthenticated = false;

	let project = { snaps: [] };

	onMount(async () => {
		let authClient = await AuthClient.create();

		isAuthenticated = await authClient.isAuthenticated();

		page_navigation.update(({ navItems }) => {
			navItems.forEach((navItem) => {
				navItem.isSelected = false;
			});
			navItems[1].isSelected = true;

			return {
				navItems: navItems
			};
		});

		if ($snap_store.snaps.length === 0) {
			snap_store.update(({ snaps }) => {
				return {
					isFetching: true,
					snaps: snaps
				};
			});
		}

		if ($project_store.projects.length > 0) {
			projects_tabs.set({
				isSnapsSelected: false,
				isProjectsSelected: true,
				isProjectSelected: false
			});
		}

		if (isAuthenticated) {
			Promise.all([
				$actor_snap_main.actor.get_all_snaps_without_project(),
				$actor_project_main.actor.get_all_projects([])
			]).then(async ([snaps, projects]) => {
				const { ok: all_projects, err: err_all_projects } = projects;
				const { ok: all_snaps, err: err_all_snaps } = snaps;

				console.log('all_snaps', all_snaps);
				console.log('all_projects', all_projects);

				if (all_snaps) {
					snap_store.set({ isFetching: false, snaps: [...all_snaps] });

					local_storage_snaps.set({ all_snaps_count: all_snaps.length || 1 });
				} else {
					if (err_all_snaps['UserNotFound'] === true) {
						await $actor_snap_main.actor.create_user_snap_storage();
					}
				}

				if (all_projects) {
					project_store.set({ isFetching: false, projects: [...all_projects] });

					local_storage_projects.set({ all_projects_count: all_projects.length || 1 });
				} else {
					if (err_all_projects['UserNotFound'] === true) {
						await $actor_project_main.actor.create_user_project_storage();
					}
				}
			});
		} else {
			window.location.href = '/';
		}
	});

	onDestroy(() => {
		projects_tabs.set({
			isSnapsSelected: true,
			isProjectsSelected: false,
			isProjectSelected: false
		});
	});

	async function fetchAllSnaps() {
		try {
			const { ok: all_snaps, err: err_all_snaps } =
				await $actor_snap_main.actor.get_all_snaps_without_project();

			if (all_snaps) {
				snap_store.set({ isFetching: false, snaps: [...all_snaps] });

				local_storage_snaps.set({ all_snaps_count: all_snaps.length || 1 });
			} else {
				if (err_all_snaps['UserNotFound'] === true) {
					await $actor_snap_main.actor.create_user_snap_storage();
				}
			}
		} catch (error) {
			console.log('fetchAllSnaps - Err: ', error);
		}
	}

	// Snaps / Project
	function deselectAllSnaps() {
		snap_store.update(({ snaps }) => {
			const new_all_snaps = snaps.map((snap) => {
				return {
					...snap,
					isSelected: false
				};
			});

			return {
				isFetching: false,
				snaps: [...new_all_snaps]
			};
		});

		if (project.snaps) {
			project.snaps = project.snaps.map((snap) => {
				return {
					...snap,
					isSelected: false
				};
			});
		}
	}

	function handleToggleEditMode(e) {
		is_edit_active.set(get(e, 'detail', false));

		deselectAllSnaps();
	}

	async function handleDeleteSnaps() {
		const snaps = $projects_tabs.isSnapsSelected
			? get($snap_store, 'snaps', [])
			: get(project, 'snaps', []);

		const selected_snaps = snaps.filter((snap) => snap.isSelected === true);
		const selected_snaps_ids = selected_snaps.map((snap) => snap.id);

		if (selected_snaps_ids.length === 0) {
			//TODO: Notification
			return 'Nothing to Delete';
		}

		// Update state to show item deleted
		const unselected_snaps = snaps.filter((snap) => snap.isSelected === false);

		if ($projects_tabs.isSnapsSelected === true) {
			snap_store.set({ isFetching: false, snaps: unselected_snaps });
		} else {
			project.snaps = unselected_snaps;
		}

		handleToggleEditMode({ detail: false });

		await $actor_snap_main.actor.delete_snaps(selected_snaps_ids);
		await fetchAllSnaps();
	}

	function handleSnapsMoveModalOpen() {
		const snaps = $projects_tabs.isSnapsSelected ? $snap_store.snaps : project.snaps;

		const selected_snaps = snaps.filter((snap) => snap.isSelected === true);

		if (selected_snaps.length > 0) {
			modal_visible.update((options) => {
				return {
					...options,
					snaps_move: !options.snaps_move
				};
			});
		}
	}

	// Projects
	function handleProjectClick(e) {
		project = get(e, 'detail');

		project.name = project.name.charAt(0).toUpperCase() + project.name.slice(1);

		projects_tabs.set({
			isSnapsSelected: false,
			isProjectsSelected: false,
			isProjectSelected: true
		});
	}

	function handleProjectRenameModalOpen(e) {
		modal_visible.update((options) => {
			return {
				...options,
				project_rename: !options.project_rename
			};
		});

		project = get(e, 'detail');
	}

	async function handleProjectDeleteModalOpen(e) {
		modal_visible.update((options) => {
			return {
				...options,
				project_options: !options.project_options
			};
		});

		project = get(e, 'detail');
	}
</script>

<svelte:head>
	<title>Projects</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 relative">
	<!-- Header Nav -->
	<div class="col-start-2 col-end-12 row-start-1 row-end-2 mb-8">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- Modals -->
	{#if $modal_visible.account_creation}
		<AccountCreationModal />
	{/if}
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}
	{#if $modal_visible.snaps_move}
		<SnapsMoveModal {project} />
	{/if}
	{#if $modal_visible.snap_creation}
		<SnapCreationModal />
	{/if}
	{#if $modal_visible.project_creation}
		<ProjectCreationModal />
	{/if}
	{#if $modal_visible.project_options}
		<ProjectOptionsDeleteModal {project} />
	{/if}
	{#if $modal_visible.project_rename}
		<ProjectRenameModal {project} />
	{/if}

	<!-- Notification -->
	{#if $notification_visible.moving_snaps}
		<div class="absolute col-start-9 col-end-12 row-start-1 row-end-2 bottom-0 right-0">
			<Notification
				is_visible={$notification_visible.moving_snaps}
				hide_delay_sec={$notification.hide_delay_sec}
			>
				<p>Moving snap(s) to</p>
				<p><strong>{$notification.project_name}</strong></p>
			</Notification>
		</div>
	{/if}

	<!-- ProjectsTabs & ProjectEditActionsBar -->
	{#if isAuthenticated}
		<div
			class="hidden lg:flex col-start-2 col-end-12 row-start-2 row-end-3 mx-4 
					self-end justify-between items-center h-10"
		>
			<ProjectsTabs
				project_name={project.name}
				projectsTabs={$projects_tabs}
				on:toggleSnaps={(e) => projects_tabs.set(e.detail)}
				on:toggleProjects={(e) => projects_tabs.set(e.detail)}
			/>
			{#if $projects_tabs.isSnapsSelected || $projects_tabs.isProjectSelected}
				<ProjectEditActionsBar
					isEditActive={$is_edit_active}
					on:clickMove={handleSnapsMoveModalOpen}
					on:toggleEditMode={handleToggleEditMode}
					on:clickRemove={handleDeleteSnaps}
				/>
			{/if}
		</div>
	{/if}

	<!-- Snaps -->
	{#if $projects_tabs.isSnapsSelected}
		<!-- Fetching Snaps -->
		{#if $snap_store.isFetching === true}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
				row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-24"
			>
				{#each { length: $local_storage_snaps.all_snaps_count } as _, i}
					<SnapCard isLoadingSnap={true} snap={{ metrics: { views: 0, likes: 0 } }} />
				{/each}
			</div>
		{/if}

		<!-- No Snaps Found -->
		{#if $snap_store.snaps.length === 0 && $snap_store.isFetching === false}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
			row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-24"
			>
				<SnapCardEmpty />
			</div>
		{/if}

		<!-- Snaps -->
		{#if $snap_store.snaps.length > 0}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-24"
			>
				{#each $snap_store.snaps as snap}
					<SnapCard {snap} isEditMode={$is_edit_active} />
				{/each}
			</div>
		{/if}
	{/if}

	<!-- Projects -->
	{#if $projects_tabs.isProjectsSelected}
		<div
			class="hidden lg:grid col-start-2 col-end-12 grid-cols-4 
			row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-24"
		>
			{#each $project_store.projects as project}
				<ProjectCard
					{project}
					showOptionsPopover={true}
					on:clickProject={handleProjectClick}
					on:clickRenameProject={handleProjectRenameModalOpen}
					on:clickDeleteProject={handleProjectDeleteModalOpen}
				/>
			{/each}
		</div>
	{/if}

	<!-- Project -->
	{#if $projects_tabs.isProjectSelected}
		<!-- Snaps -->
		{#if project.snaps && project.snaps.length > 0}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-24"
			>
				{#each project.snaps as snap}
					<SnapCard {snap} isEditMode={$is_edit_active} />
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
