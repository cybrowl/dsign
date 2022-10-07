<script>
	import { onMount } from 'svelte';
	import { AuthClient } from '@dfinity/auth-client';
	import get from 'lodash/get.js';

	import Login from '../../components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProjectEditActionsBar from 'dsign-components/components/ProjectEditActionsBar.svelte';
	import ProjectsTabs from 'dsign-components/components/ProjectsTabs.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCardEmpty from 'dsign-components/components/SnapCardEmpty.svelte';

	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../modals/AccountSettingsModal.svelte';
	import MoveSnapsModal from '../../modals/MoveSnapsModal.svelte';
	import SnapCreationModal from '../../modals/SnapCreationModal.svelte';

	import {
		isAccountCreationModalVisible,
		isAccountSettingsModalVisible,
		isMoveSnapsModalVisible,
		isSnapCreationModalVisible
	} from '../../store/modal';

	// actors
	import { actor_project_main, project_store } from '../../store/actor_project_main';
	import { actor_snap_main, snap_store } from '../../store/actor_snap_main';

	// local storage
	import { local_storage_snaps, local_storage_projects } from '../../store/local_storage';

	// page navigation
	import { page_navigation } from '../../store/page_navigation';

	let isAuthenticated = false;
	let isEditActive = false;
	let number_snaps_selected = 0;

	let projectsTabs = {
		isSnapsSelected: true,
		isProjectsSelected: false
	};

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

		if ($project_store.projects.length === 0) {
			project_store.update(({ projects }) => {
				return {
					isFetching: true,
					projects: projects
				};
			});
		}

		if (isAuthenticated) {
			await getAllSnaps();
			await getAllProjects();
		} else {
			window.location.href = '/';
		}
	});

	async function getAllSnaps() {
		try {
			const { ok: all_snaps, err: error } = await $actor_snap_main.actor.get_all_snaps();

			console.log('call: all_snaps', all_snaps);

			if (all_snaps) {
				snap_store.set({ isFetching: false, snaps: [...all_snaps] });

				local_storage_snaps.set({ all_snaps_count: all_snaps.length || 1 });
			} else {
			}
		} catch (error) {
			await $actor_snap_main.actor.create_user_snap_storage();
			console.log('error: ', error);
		}
	}

	async function getAllProjects() {
		try {
			const { ok: all_projects, err: error } = await $actor_project_main.actor.get_all_projects();

			console.log('call error: ', error);
			console.log('call all_projects: ', all_projects);

			if (all_projects) {
				project_store.set({ isFetching: false, projects: [...all_projects] });

				local_storage_projects.set({ all_projects_count: all_projects.length || 1 });
			} else {
				if (error['UserNotFound'] === true) {
					console.log("create user's project storage");
				}
			}
		} catch (error) {
			console.log('error: ', error);
			await $actor_project_main.actor.create_user_project_storage();
		}
	}

	function handleToggleEditMode(e) {
		isEditActive = get(e, 'detail');

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
	}

	async function handleDeleteSnaps(e) {
		const selected_snaps = $snap_store.snaps.filter((snap) => snap.isSelected === true);
		const unselected_snaps = $snap_store.snaps.filter((snap) => snap.isSelected === false);
		const selected_snaps_ids = selected_snaps.map((snap) => snap.id);

		snap_store.set({ isFetching: false, snaps: unselected_snaps });

		handleToggleEditMode({ detail: false });

		await $actor_snap_main.actor.delete_snaps(selected_snaps_ids);
		await getAllSnaps();
	}

	function handleOpenMoveSnapsModal() {
		const selected_snaps = $snap_store.snaps.filter((snap) => snap.isSelected === true);

		number_snaps_selected = selected_snaps.length;

		if (selected_snaps.length > 0) {
			isMoveSnapsModalVisible.update((isMoveSnapsModalVisible) => !isMoveSnapsModalVisible);
		}
	}
</script>

<!-- src/routes/projects.svelte -->
<svelte:head>
	<title>Projects</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-16">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	{#if $isAccountCreationModalVisible}
		<AccountCreationModal />
	{/if}
	{#if $isAccountSettingsModalVisible}
		<AccountSettingsModal />
	{/if}
	{#if $isMoveSnapsModalVisible}
		<MoveSnapsModal {number_snaps_selected} />
	{/if}
	{#if $isSnapCreationModalVisible}
		<SnapCreationModal />
	{/if}

	{#if isAuthenticated}
		<div
			class="flex col-start-2 col-end-12 row-start-2 row-end-auto mx-4 
					self-end justify-between items-center"
		>
			<ProjectsTabs
				{projectsTabs}
				on:toggleSnaps={(e) => (projectsTabs = e.detail)}
				on:toggleProjects={(e) => (projectsTabs = e.detail)}
			/>
			<ProjectEditActionsBar
				{isEditActive}
				on:clickMove={handleOpenMoveSnapsModal}
				on:toggleEditMode={handleToggleEditMode}
				on:clickRemove={handleDeleteSnaps}
			/>
		</div>
	{/if}

	{#if projectsTabs.isSnapsSelected}
		<!-- Fetching Snaps -->
		{#if $snap_store.isFetching === true}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
					row-start-3 row-end-auto mx-4 gap-10 mt-2 mb-16"
			>
				{#each { length: $local_storage_snaps.all_snaps_count } as _, i}
					<SnapCard isLoadingSnap={true} snap={{ metrics: { views: 0, likes: 0 } }} />
				{/each}
			</div>
		{/if}

		<!-- No Snaps Found -->
		{#if $snap_store.snaps.length === 0 && $snap_store.isFetching === false}
			<div
				class="flex col-start-2 col-end-12 row-start-3 row-end-auto mx-4 mt-2
		"
			>
				<SnapCardEmpty />
			</div>
		{/if}

		<!-- Snaps -->
		{#if $snap_store.snaps.length > 0}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-16"
			>
				{#each $snap_store.snaps as snap}
					<SnapCard {snap} isEditMode={isEditActive} />
				{/each}
			</div>
		{/if}
	{/if}
</main>

<style>
</style>
