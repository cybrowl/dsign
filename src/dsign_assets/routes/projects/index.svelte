<script>
	import { onMount } from 'svelte';
	import { AuthClient } from '@dfinity/auth-client';

	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../modals/AccountSettingsModal.svelte';
	import Header from '../../components/Header.svelte';
	import ProjectEditActionsBar from 'dsign-components/components/ProjectEditActionsBar.svelte';
	import ProjectsTabs from 'dsign-components/components/ProjectsTabs.svelte';
	import SnapCreationModal from '../../modals/SnapCreationModal.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCardEmpty from 'dsign-components/components/SnapCardEmpty.svelte';

	import {
		isAccountSettingsModalVisible,
		isAccountCreationModalVisible,
		isSnapCreationModalVisible
	} from '../../store/modal';

	import { actor_snap_main, snap_storage } from '../../store/actor_snap_main';

	let isAuthenticated = false;

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

		if (isAuthenticated) {
			const all_snaps = await $actor_snap_main.actor.get_all_snaps();

			snap_storage.set({ isFetching: false, ...all_snaps });

			console.log('all_snaps: ', $snap_storage.ok);
		} else {
			window.location.href = '/';
		}
	});
</script>

<!-- src/routes/projects.svelte -->
<svelte:head>
	<title>Projects</title>
</svelte:head>

<main>
	<html lang="en" class="dark">
		<body class="dark:bg-backdrop dark:text-gray-200 h-screen">
			<div class="grid grid-cols-12 gap-y-2">
				<Header />

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
						<ProjectsTabs />
						<ProjectEditActionsBar />
					</div>
				{/if}

				<!-- Fetching Snaps -->
				{#if $snap_storage.isFetching === true}
					<div class="flex col-start-2 col-end-12 row-start-3 row-end-auto mx-4">
						<SnapCard isLoadingSnap={true} />
					</div>
				{/if}

				<!-- No Snaps Found -->
				{#if $snap_storage.ok.length === 0}
					<div class="flex col-start-2 col-end-12 row-start-3 row-end-auto mx-4">
						<SnapCardEmpty />
					</div>
				{/if}

				<!-- Snaps -->
				{#if $snap_storage.ok.length > 1}
					<div
						class="flex flex-wrap col-start-2 col-end-12 
						row-start-3 row-end-10 mx-4 justify-between"
					>
						{#each $snap_storage.ok as snap}
							<span class="mt-10">
								<SnapCard {snap} />
							</span>
						{/each}
					</div>
				{/if}
			</div>
		</body>
	</html>
</main>

<style>
</style>
