<!-- src/routes/profile.svelte -->
<script>
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { AuthClient } from '@dfinity/auth-client';
	import get from 'lodash/get';

	// components
	import AccountCreationModal from '$modals_ref/AccountCreationModal.svelte';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProfileBanner from 'dsign-components/components/ProfileBanner.svelte';
	import ProfileInfo from 'dsign-components/components/ProfileInfo.svelte';
	import SnapCreationModal from '$modals_ref/SnapCreationModal.svelte';

	// stores
	import { actor_profile, actor_snap_main, actor_project_main } from '$stores_ref/actors';
	import { snap_store, project_store } from '$stores_ref/fetch_store';

	import { local_storage_profile } from '$stores_ref/local_storage';
	import { modal_visible } from '$stores_ref/modal';
	import modal_update from '$stores_ref/modal_update';
	import { page_navigation } from '$stores_ref/page_navigation';
	import page_navigation_update from '$stores_ref/page_navigation_update';

	// variables
	let isAuthenticated = false;
	let isProfileOwner = false;
	let profile_info = {
		profile: {
			avatar: {
				url: ''
			},
			username: ''
		},
		projects: []
	};

	// execution
	page_navigation_update.select_item(3);

	onMount(async () => {
		let authClient = await AuthClient.create();

		isAuthenticated = await authClient.isAuthenticated();

		if (isAuthenticated && $local_storage_profile.username === $page.params.slug) {
			isProfileOwner = true;
		} else {
			isProfileOwner = false;
		}

		try {
			if (isAuthenticated) {
				const { ok: profile } = await $actor_profile.actor.get_profile();
				profile_info.profile = profile;

				if (profile.username === $page.params.slug) {
					isProfileOwner = true;
				}

				const projects = await $actor_project_main.actor.get_all_projects();

				console.log(projects);
			}

			// const { ok: all_snaps, err: error } =
			// 	await $actor_snap_main.actor.get_all_snaps_without_project();

			// console.log('profile: all_snaps', all_snaps);
			// console.log('profile: error', error);
			// if (all_snaps) {
			// 	snap_store.set({ isFetching: false, snaps: [...all_snaps] });

			// 	local_storage_snaps.set({ all_snaps_count: all_snaps.length || 1 });
			// } else {
			// }
		} catch (error) {
			// await $actor_snap_main.actor.create_user_snap_storage();
			// console.log('error: ', error);
		}
	});

	function openSettingsModal() {
		if (isProfileOwner) {
			modal_update.change_visibility('account_settings');
		}
	}
</script>

<svelte:head>
	<title>Profile</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 relative">
	<div class="col-start-2 col-end-12 row-start-1 row-end-2">
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

	<div class="relative col-start-2 col-end-4 row-start-2 row-end-3">
		<ProfileInfo
			avatar={get(profile_info, 'profile.avatar.url', '')}
			is_authenticated={isProfileOwner}
			username={get(profile_info, 'profile.username', '')}
			on:editProfile={openSettingsModal}
		/>
	</div>

	<div class="col-start-4 col-end-12 row-start-2 row-end-3">
		<ProfileBanner
			is_authenticated={isProfileOwner}
			profile_banner_url="/default_profile_banner.png"
		/>
	</div>
</main>

<style>
</style>
