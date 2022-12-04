<script>
	import { onMount } from 'svelte';
	import { AuthClient } from '@dfinity/auth-client';

	import Login from '../components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';

	import AccountSettingsModal from '../modals/AccountSettingsModal.svelte';
	import SnapCreationModal from '../modals/SnapCreationModal.svelte';

	import { modal_visible } from '../store/modal';
	import { page_navigation } from '../store/page_navigation';
	import { actor_explore } from '$stores_ref/actors.js';
	import { explore_store } from '$stores_ref/fetch_store.js';

	let isAuthenticated = false;

	page_navigation.update(({ navItems }) => {
		navItems.forEach((navItem) => {
			navItem.isSelected = false;
		});
		navItems[0].isSelected = true;

		return {
			navItems: navItems
		};
	});

	console.log('explore_store', $actor_explore.loggedIn);

	onMount(async () => {
		let authClient = await AuthClient.create();

		isAuthenticated = await authClient.isAuthenticated();

		try {
			const all_snaps = await $actor_explore.actor.get_all_snaps();

			console.log('all_snaps: ', all_snaps);

			if (all_snaps) {
				explore_store.set({ isFetching: false, snaps: [...all_snaps] });
			}
		} catch (error) {
			console.log('error: call', error);

			await authClient.logout();
		}
	});
</script>

<!-- Explore -->
<svelte:head>
	<title>DSign</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 relative">
	<div class="col-start-2 col-end-12 mb-8">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<!-- SnapCreationModal -->
	{#if $modal_visible.snap_creation}
		<SnapCreationModal />
	{/if}

	<!-- Snaps -->
	{#if $explore_store.snaps.length > 0}
		<div
			class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-x-10 gap-y-20 mt-2 mb-24"
		>
			{#each $explore_store.snaps as snap}
				<SnapCard {snap} showUsername={true} />
			{/each}
		</div>
	{/if}
</main>

<!-- Mobile Not Supported -->
<div class="grid lg:hidden h-screen place-items-center text-white text-4xl">
	<h1>Sorry, Mobile Not Supported</h1>
</div>

<style>
</style>
