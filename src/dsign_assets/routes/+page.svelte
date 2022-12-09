<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import get from 'lodash/get.js';

	import Login from '../components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';

	import AccountSettingsModal from '../modals/AccountSettingsModal.svelte';
	import SnapCreationModal from '../modals/SnapCreationModal.svelte';

	import { actor_explore, actor_profile, actor_favorite_main } from '$stores_ref/actors.js';
	import { explore_store } from '$stores_ref/fetch_store.js';
	import { local_storage_profile } from '$stores_ref/local_storage';
	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation } from '$stores_ref/page_navigation';

	page_navigation.update(({ navItems }) => {
		navItems.forEach((navItem) => {
			navItem.isSelected = false;
		});
		navItems[0].isSelected = true;

		return {
			navItems: navItems
		};
	});

	onMount(async () => {
		try {
			const all_snaps = await $actor_explore.actor.get_all_snaps();

			if (all_snaps) {
				explore_store.set({ isFetching: false, snaps: [...all_snaps] });
			}
		} catch (error) {
			console.error('error: call', error);

			// await authClient.logout();
		}

		if ($actor_profile.loggedIn) {
			try {
				let { ok: profile, err: err_profile } = await $actor_profile.actor.get_profile();

				if (err_profile) {
					if (err_profile['ProfileNotFound'] === true) {
						goto('/account_creation');
					}
				}

				if (profile) {
					local_storage_profile.set({
						avatar_url: get(profile, 'avatar.url', ''),
						username: get(profile, 'username', '')
					});
				}
			} catch (error) {
				// goto('/');
			}
		}

		if ($actor_favorite_main.loggedIn) {
			try {
				const response = await $actor_favorite_main.actor.version();
				console.log('fav: ', response);
			} catch (error) {
				console.error('error: call', error);
			}
		}
	});

	async function handleClickLike(e) {
		const snap_liked = e.detail;

		try {
			const { ok: saved_snap, err: err_save_snap } = await $actor_favorite_main.actor.save_snap(
				snap_liked
			);

			console.log('saved_snap: ', saved_snap);
			console.log('err_save_snap: ', err_save_snap);

			if (err_save_snap && err_save_snap['UserNotFound'] === true) {
				await $actor_favorite_main.actor.create_user_favorite_storage();
			}
		} catch (error) {
			console.log('error: call', error);
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
