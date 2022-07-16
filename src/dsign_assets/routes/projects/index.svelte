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
				ok: {
					...snaps.ok
				}
			};
		});

		console.log('snap_storage.ok: ', $snap_storage.ok);

		if (isAuthenticated) {
			const all_snaps = await $actor_snap_main.actor.get_all_snaps();

			snap_storage.set({ isFetching: false, ...all_snaps });

			console.log('all_snaps: ', $snap_storage.ok);
		} else {
			window.location.href = '/';
		}
	});

	function handleToggleEditMode(e) {
		const isEditActive = get(e, 'detail');
		console.log('isEditActive: ', isEditActive);

		isEditMode = isEditActive;

		snap_storage.update((snaps) => {
			const all_snaps = snaps.ok;

			const new_all_snaps = all_snaps.map((snap) => {
				return {
					...snap,
					isSelected: false
				};
			});

			return {
				isFetching: false,
				ok: [...new_all_snaps]
			};
		});

		console.log('snap_storage.ok: ', $snap_storage.ok);
	}
</script>

<!-- src/routes/projects.svelte -->
<svelte:head>
	<title>Projects</title>
</svelte:head>

<main>
	<html lang="en" class="dark">
		<body class="dark:bg-backdrop dark:text-gray-200 h-screen">
			<div class="grid grid-cols-12 gap-y-2">
				<div class="col-start-2 col-end-12 mb-24">
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
					row-start-3 row-end-auto mx-4 gap-10 mt-10"
					>
						<SnapCard isLoadingSnap={true} snap={{ views: 0, likes: 0 }} />
					</div>
				{/if}

				<!-- No Snaps Found -->
				{#if $snap_storage.ok.length === 0}
					<div class="flex col-start-2 col-end-12 row-start-3 row-end-auto mx-4 mt-10">
						<SnapCardEmpty />
					</div>
				{/if}

				<!-- Snaps -->
				{@debug isEditMode}
				{#if $snap_storage.ok.length > 0}
					<div
						class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-10 mt-10"
					>
						{#each $snap_storage.ok as snap}
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
