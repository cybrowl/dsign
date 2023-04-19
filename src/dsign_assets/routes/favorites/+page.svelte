<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	import Login from '../../components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';
	import SnapCardFavoriteEmpty from 'dsign-components/components/SnapCardFavoriteEmpty.svelte';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import SnapCreationModal from '$modals_ref/SnapCreationModal.svelte';

	import { actor_favorite_main } from '$stores_ref/actors';
	import { auth_favorite_main } from '$stores_ref/auth_client';
	import { favorite_store, favorite_store_fetching } from '$stores_ref/fetch_store';
	import { local_storage_favorites } from '$stores_ref/local_storage';
	import { modal_visible } from '$stores_ref/modal';
	import page_navigation_update, {
		navigate_to_home_with_notification,
		page_navigation,
		snap_preview
	} from '$stores_ref/page_navigation';

	// page_navigation_update.select_item(0);

	$favorite_store.snaps.length === 0 && favorite_store_fetching();

	onMount(async () => {
		await auth_favorite_main();

		if ($actor_favorite_main.loggedIn) {
			try {
				const { ok: all_favs, err: err_get_all_favs } =
					await $actor_favorite_main.actor.get_all_snaps();

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
			} catch (error) {
				console.log(error);
			}
		} else {
			navigate_to_home_with_notification();
		}
	});

	async function handleClickLike(e) {
		const snap_liked = e.detail;

		try {
			const filtered_fav_snaps = $favorite_store.snaps.filter((snap) => snap.id !== snap_liked.id);
			favorite_store.set({ isFetching: false, snaps: filtered_fav_snaps });
			local_storage_favorites.set({ all_favorites_count: filtered_fav_snaps.length || 1 });

			const { ok: delete_snap, err: err_delete_snap } =
				await $actor_favorite_main.actor.delete_snap(snap_liked.id);
		} catch (error) {
			console.log('error: call', error);
		}
	}

	function handleSnapPreviewModalOpen(e) {
		const snap = e.detail;
		snap_preview.set(snap);

		goto('/snap/' + snap.id + '?canister_id=' + snap.canister_id);
	}
</script>

<svelte:head>
	<title>Favorites</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-8">
		<PageNavigation navigationItems={$page_navigation.navigationItems}>
			<Login />
		</PageNavigation>
	</div>

	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}
	{#if $modal_visible.snap_creation}
		<SnapCreationModal />
	{/if}

	{#if $actor_favorite_main.loggedIn}
		<!-- Fetching Snaps -->
		{#if $favorite_store.isFetching === true}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
		row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-24"
			>
				{#each { length: $local_storage_favorites.all_favorites_count } as _, i}
					<SnapCard isLoadingSnap={true} showMetricLikesNumber={false} />
				{/each}
			</div>
		{/if}

		<!-- No Snaps Found -->
		{#if $favorite_store.snaps.length === 0 && $favorite_store.isFetching === false}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
			row-start-3 row-end-auto mx-4 gap-x-10 gap-y-12 mt-2 mb-24"
			>
				<SnapCardFavoriteEmpty />
			</div>
		{/if}

		<!-- Snaps -->
		{#if $favorite_store.snaps.length > 0}
			<div
				class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-x-10 gap-y-20 mt-2 mb-24"
			>
				{#each $favorite_store.snaps as snap}
					<SnapCard
						{snap}
						showUsername={true}
						showMetricLikesNumber={false}
						on:clickCard={handleSnapPreviewModalOpen}
						on:clickLike={handleClickLike}
					/>
				{/each}
			</div>
		{/if}
	{/if}
</main>

<style>
</style>
