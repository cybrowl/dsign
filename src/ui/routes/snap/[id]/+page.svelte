<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { get, last, isEmpty } from 'lodash';

	import Login from '$components_ref/Login.svelte';
	import { SnapActionsBar, PageNavigation, SnapInfo } from 'dsign-components';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import {} from '$stores_ref/actors';
	import { auth, init_auth } from '$stores_ref/auth_client';
	import { disable_project_store_reset } from '$stores_ref/page_state';
	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation, snap_creation } from '$stores_ref/page_navigation';
	import { snap_project_store, snap_preview_store } from '$stores_ref/data_snap';

	disable_project_store_reset.set(true);

	let is_owner = false;

	onMount(async () => {
		const canister_id = $page.url.searchParams.get('canister_id');
		const snap_id = last(get($page, 'url.pathname', '').split('/'));

		await init_auth();
		await Promise.all([]);

		try {
			const creator_logged_in = false;

			if (creator_logged_in) {
				//TODO: get snap
				//TODO: get profile
			}
		} catch (error) {
			console.log('error snap preview: ', error);
		}
	});

	function go_back_history() {
		const project = get($snap_project_store, 'project', '');

		if (!isEmpty(project)) {
			goto(`/project/${project.name}?id=${project.id}&cid=${project.canister_id}`);
		} else {
			goto(`/${$snap_preview_store.snap.username}`);
		}
	}

	function goto_edit_snap() {
		goto(`/snap/edit`);
	}
</script>

<svelte:head>
	<title>Snap</title>
</svelte:head>

<main class="grid_layout">
	<div class="navigation_main_layout">
		<PageNavigation
			navigationItems={$page_navigation.navigationItems}
			on:home={() => {
				goto('/');
			}}
		>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<!-- Snap -->
	{#if $snap_preview_store.snap.id !== undefined}
		<div class="snap_info_layout">
			<SnapInfo
				snap={$snap_preview_store.snap}
				project_name={get($snap_project_store, 'project.name', '')}
				{is_owner}
				on:edit={goto_edit_snap}
			/>
		</div>

		<div class="content_layout">
			{#each $snap_preview_store.snap.images as image}
				<img src={image.url} alt="" />
			{/each}
		</div>

		<div class="actions_bar_layout">
			<SnapActionsBar snap={$snap_preview_store.snap} on:clickBack={go_back_history} />
		</div>
	{/if}
</main>

<!-- Mobile Not Supported -->
{#if $snap_preview_store.snap.id !== undefined}
	<div class="grid lg:hidden h-screen place-items-center text-white text-4xl">
		<h1>Sorry, Mobile Not Supported</h1>
	</div>
{/if}

<style lang="postcss">
	.grid_layout {
		@apply hidden lg:grid grid-cols-12 gap-y-2 mx-12 2xl:mx-60;
	}
	.navigation_main_layout {
		@apply row-start-1 row-end-auto col-start-1 col-end-13;
	}
	.snap_info_layout {
		@apply row-start-2 row-end-auto col-start-1 col-end-13 mb-10;
	}
	.content_layout {
		@apply row-start-3 row-end-auto col-start-1 col-end-12 mb-10 flex flex-col items-center;
	}
	.content_layout img {
		@apply pb-10 max-w-full;
	}
	.actions_bar_layout {
		@apply row-start-3 row-end-auto col-start-12 col-end-13 mb-10 flex justify-center;
	}
</style>
