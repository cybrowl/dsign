<!-- src/routes/favorites.svelte -->
<script>
	import { onMount } from 'svelte';

	import Login from '../../components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCardEmpty from 'dsign-components/components/SnapCardEmpty.svelte';

	import AccountSettingsModal from '../../modals/AccountSettingsModal.svelte';
	import SnapCreationModal from '../../modals/SnapCreationModal.svelte';

	import { actor_favorite_main } from '$stores_ref/actors';
	import { auth_favorite_main } from '$stores_ref/auth_client';
	import { favorite_store } from '$stores_ref/fetch_store';
	import { local_storage_favorites } from '$stores_ref/local_storage';
	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation } from '$stores_ref/page_navigation';

	page_navigation.update(({ navItems }) => {
		navItems.forEach((navItem) => {
			navItem.isSelected = false;
		});
		navItems[2].isSelected = true;

		return {
			navItems: navItems
		};
	});

	if ($favorite_store.snaps.length === 0) {
		favorite_store.update(({ snaps }) => {
			return {
				isFetching: true,
				snaps: snaps
			};
		});
	}

	onMount(async () => {
		await auth_favorite_main();

		if ($actor_favorite_main.loggedIn) {
			try {
				const { ok: all_favs, err: err_get_all_favs } =
					await $actor_favorite_main.actor.get_all_snaps();

				if (all_favs) {
					favorite_store.set({ isFetching: false, snaps: [...all_favs] });
					local_storage_favorites.set({ all_favorites_count: all_favs.length || 1 });
				} else {
					favorite_store.set({ isFetching: false, snaps: [] });
					local_storage_favorites.set({ all_favorites_count: 1 });
				}

				console.log('all_favs: ', all_favs);
				console.log('err_get_all_favs: ', err_get_all_favs);
			} catch (error) {
				console.log(error);
			}
		}
	});

	async function handleClickLike(e) {
		const snap_liked = e.detail;

		try {
			const { ok: delete_snap, err: err_delete_snap } =
				await $actor_favorite_main.actor.delete_snap(snap_liked.id);

			console.log('delete_snap: ', delete_snap);
			console.log('err_delete_snap: ', err_delete_snap);

			if (err_delete_snap && err_delete_snap['UserNotFound'] === true) {
				await $actor_favorite_main.actor.create_user_favorite_storage();
			}
		} catch (error) {
			console.log('error: call', error);
		}
	}
</script>

<svelte:head>
	<title>Favorites</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
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

	<!-- Fetching Snaps -->
	{#if $favorite_store.isFetching === true}
		<div
			class="col-start-2 col-end-12 grid grid-cols-4 
		row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-24"
		>
			{#each { length: $local_storage_favorites.all_favorites_count } as _, i}
				<SnapCard isLoadingSnap={true} snap={{ metrics: { views: 0, likes: 0 } }} />
			{/each}
		</div>
	{/if}

	<!-- No Snaps Found -->
	{#if $favorite_store.snaps.length === 0 && $favorite_store.isFetching === false}
		<div
			class="col-start-2 col-end-12 grid grid-cols-4 
			row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-24"
		>
			<SnapCardEmpty />
		</div>
	{/if}

	<!-- Snaps -->
	{#if $favorite_store.snaps.length > 0}
		<div
			class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-x-10 gap-y-20 mt-2 mb-24"
		>
			{#each $favorite_store.snaps as snap}
				<SnapCard {snap} showUsername={true} showMetrics={false} on:clickLike={handleClickLike} />
			{/each}
		</div>
	{/if}
</main>

<style>
</style>
