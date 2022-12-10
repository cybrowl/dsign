<script>
	import { onMount } from 'svelte';

	import Login from '../components/Login.svelte';
	import Notification from 'dsign-components/components/Notification.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';

	import AccountSettingsModal from '../modals/AccountSettingsModal.svelte';
	import SnapCreationModal from '../modals/SnapCreationModal.svelte';

	import { actor_explore, actor_favorite_main } from '$stores_ref/actors.js';
	import { auth_favorite_main } from '$stores_ref/auth_client';
	import { explore_store } from '$stores_ref/fetch_store.js';
	import { modal_visible } from '$stores_ref/modal';
	import { notification_visible, notification } from '$stores_ref/notification';
	import page_navigation_update, { page_navigation } from '$stores_ref/page_navigation';

	page_navigation_update.select_item(0);

	onMount(async () => {
		if ($notification.message.length === 0) {
			await auth_favorite_main();
		}

		try {
			const all_snaps = await $actor_explore.actor.get_all_snaps();
			if (all_snaps) {
				explore_store.set({ isFetching: false, snaps: [...all_snaps] });
			}
		} catch (error) {
			console.error('error: call', error);
		}
	});

	async function handleClickLike(e) {
		const snap_liked = e.detail;

		if ($actor_favorite_main.loggedIn) {
			try {
				const { ok: saved_snap, err: err_save_snap } = await $actor_favorite_main.actor.save_snap(
					snap_liked
				);

				if (err_save_snap && err_save_snap['UserNotFound'] === true) {
					await $actor_favorite_main.actor.create_user_favorite_storage();
				}
			} catch (error) {
				//TODO: log error
			}
		}
	}
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

	<!-- Notification -->
	{#if $notification_visible.auth_error}
		<div class="absolute col-start-9 col-end-12 row-start-1 row-end-2 bottom-0 right-0">
			<Notification is_visible={$notification_visible.auth_error} hide_delay_sec={2000}>
				<p>{$notification.message}</p>
			</Notification>
		</div>
	{/if}

	<!-- Snaps -->
	{#if $explore_store.snaps.length > 0}
		<div
			class="col-start-2 col-end-12 grid grid-cols-4 
						row-start-3 row-end-auto mx-4 gap-x-10 gap-y-20 mt-2 mb-24"
		>
			{#each $explore_store.snaps as snap}
				<SnapCard {snap} showUsername={true} on:clickLike={handleClickLike} />
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
