<script>
	import { onMount } from 'svelte';
	import { AuthClient } from '@dfinity/auth-client';
	import get from 'lodash/get.js';

	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../modals/AccountSettingsModal.svelte';
	import Login from './components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProjectEditActionsBar from 'dsign-components/components/ProjectEditActionsBar.svelte';
	import ProjectsTabs from 'dsign-components/components/ProjectsTabs.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCardEmpty from 'dsign-components/components/SnapCardEmpty.svelte';
	import SnapCreationModal from '../../modals/SnapCreationModal.svelte';

	import {
		isAccountSettingsModalVisible,
		isAccountCreationModalVisible,
		isSnapCreationModalVisible
	} from '../../store/modal';

	import { actor_snap_main, snap_store } from '../../store/actor_snap_main';
	import { local_storage_projects } from '../../store/local_storage';

	let isAuthenticated = false;
	let isEditMode = false;

	onMount(async () => {
		let authClient = await AuthClient.create();

		isAuthenticated = await authClient.isAuthenticated();

		if ($snap_store.snaps.length === 0) {
			snap_store.update((snaps) => {
				return {
					isFetching: true,
					snaps: snaps
				};
			});
		}

		if (isAuthenticated) {
			const all_snaps = await $actor_snap_main.actor.get_all_snaps();

			snap_store.set({ isFetching: false, snaps: [...all_snaps.ok] });

			local_storage_projects.set({ all_snaps_count: all_snaps.ok.length || 1 });
		} else {
			window.location.href = '/';
		}
	});

	function handleToggleEditMode(e) {
		const isEditActive = get(e, 'detail');

		isEditMode = isEditActive;

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
</script>

<!-- src/routes/projects.svelte -->
<svelte:head>
	<title>Projects</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-16">
		<PageNavigation>
			<Login />
		</PageNavigation>
	</div>

	{#if $isAccountSettingsModalVisible}
		<AccountSettingsModal />
	{/if}
	{#if $isAccountCreationModalVisible}
		<AccountCreationModal />
	{/if}
	{#if $isSnapCreationModalVisible}
		<SnapCreationModal />
	{/if}

	{#if isAuthenticated}
		<div
			class="flex col-start-2 col-end-12 row-start-2 row-end-auto mx-4 
					self-end justify-between items-center"
		>
			<ProjectsTabs isSnapsSelected={true} />
			<ProjectEditActionsBar on:toggleEditMode={handleToggleEditMode} />
		</div>
	{/if}

	<!-- Fetching Snaps -->
	{#if $snap_store.isFetching === true}
		<div
			class="col-start-2 col-end-12 grid grid-cols-4 
					row-start-3 row-end-auto mx-4 gap-10 mt-2 mb-16"
		>
			{#each { length: $local_storage_projects.all_snaps_count } as _, i}
				<SnapCard isLoadingSnap={true} snap={{ views: 0, likes: 0 }} />
			{/each}
		</div>
	{/if}

	<!-- No Snaps Found -->
	{#if $snap_store.snaps.length === 0}
		<div class="flex col-start-2 col-end-12 row-start-3 row-end-auto mx-4 mt-10">
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
				<SnapCard {snap} {isEditMode} />
			{/each}
		</div>
	{/if}
</main>

<style>
</style>
