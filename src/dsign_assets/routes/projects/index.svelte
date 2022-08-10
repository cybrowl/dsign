<script>
	import { onMount } from 'svelte';
	import { AuthClient } from '@dfinity/auth-client';
	import get from 'lodash/get.js';

	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../modals/AccountSettingsModal.svelte';
	import Header from '../../components/Header.svelte';
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

	import { actor_snap_main, snap_storage } from '../../store/actor_snap_main';

	let isAuthenticated = false;
	let isEditMode = false;

	onMount(async () => {
		let authClient = await AuthClient.create();

		isAuthenticated = await authClient.isAuthenticated();

		snap_storage.update((snaps) => {
			return {
				isFetching: true,
				snaps: {
					...snaps.ok
				}
			};
		});

		if (isAuthenticated) {
			const all_snaps = await $actor_snap_main.actor.get_all_snaps();

			console.log("all_snaps: ", all_snaps);

			snap_storage.set({ isFetching: false, snaps: [...all_snaps.ok]});

		} else {
			window.location.href = '/';
		}
	});

	function handleToggleEditMode(e) {
		const isEditActive = get(e, 'detail');

		isEditMode = isEditActive;

		snap_storage.update(({snaps}) => {

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

<main>
	<html lang="en" class="dark">
		<body class="dark:bg-backdrop dark:text-gray-200">
			<div class="grid grid-cols-12 gap-y-2">
				<div class="col-start-2 col-end-12 mb-16">
					<Header />
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
				{#if $snap_storage.isFetching === true}
					<div
						class="col-start-2 col-end-12 grid grid-cols-4 
					row-start-3 row-end-auto mx-4 gap-10 mt-10 h-screen"
					>
						<SnapCard isLoadingSnap={true} snap={{ views: 0, likes: 0 }} />
					</div>
				{/if}

				<!-- No Snaps Found -->
				{#if $snap_storage.snaps.length === 0}
					<div class="flex col-start-2 col-end-12 row-start-3 row-end-auto mx-4 mt-10 h-screen">
						<SnapCardEmpty />
					</div>
				{/if}

				<!-- Snaps -->
				{#if $snap_storage.snaps.length > 0}
					<div
						class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-10 mb-16"
					>
						{#each $snap_storage.snaps as snap}
							<SnapCard {snap} {isEditMode} />
						{/each}
					</div>
				{/if}
			</div>
		</body>
	</html>
</main>

<style>
</style>
