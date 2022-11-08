<!-- src/routes/profile.svelte -->
<script>
	import { onMount } from 'svelte';
	import { page } from '$app/stores';

	import AccountCreationModal from '../../../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../../modals/AccountSettingsModal.svelte';
	import Login from '../../../components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapCreationModal from '../../../modals/SnapCreationModal.svelte';

	import { modal_visible } from '../../../store/modal';
	import { page_navigation } from '../../../store/page_navigation';

	import { actor_snap_main, snap_store } from '../../../store/actor_snap_main';

	console.log($page.params);

	page_navigation.update(({ navItems }) => {
		navItems.forEach((navItem) => {
			navItem.isSelected = false;
		});
		navItems[3].isSelected = true;

		return {
			navItems: navItems
		};
	});

	onMount(async () => {
		try {
			const { ok: all_snaps, err: error } =
				await $actor_snap_main.actor.get_all_snaps_without_project();

			console.log('profile: all_snaps', all_snaps);
			console.log('profile: error', error);
			if (all_snaps) {
				snap_store.set({ isFetching: false, snaps: [...all_snaps] });

				local_storage_snaps.set({ all_snaps_count: all_snaps.length || 1 });
			} else {
			}
		} catch (error) {
			await $actor_snap_main.actor.create_user_snap_storage();
			console.log('error: ', error);
		}
	});
</script>

<svelte:head>
	<title>Profile</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-24">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<!-- AccountCreationModal -->
	{#if $modal_visible.account_creation}
		<AccountCreationModal />
	{/if}

	<!-- SnapCreationModal -->
	{#if $modal_visible.snap_creation}
		<SnapCreationModal />
	{/if}

	<div class="h-screen" />
</main>

<style>
</style>
