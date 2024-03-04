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
	import { page_navigation, snap_creation, snap_preview } from '$stores_ref/page_navigation';

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

	function handleClickBackHistory() {
		const project_id = get($snap_preview, 'project_ref[0].id', '');
		const project_canister = get($snap_preview, 'project_ref[0].canister_id', '');
		const project_href = `/project/${project_id}/?canister_id=${project_canister}`;

		if (!isEmpty(project_id)) {
			goto(project_href);
		} else {
			goto(`/${$snap_preview.username}`);
		}
	}

	function handleClickEdit() {
		let project_id = get($snap_preview, 'project_ref[0].id', '');
		let project_canister = get($snap_preview, 'project_ref[0].canister_id', '');

		snap_creation.update(() => ({
			...$snap_preview
		}));

		console.log('$snap_preview: ', $snap_preview);

		if (project_id) {
			goto(`/snap/upsert?project_id=${project_id}&canister_id=${project_canister}&mode=edit`);
		}
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
	{#if $snap_preview.id !== undefined}
		<div class="snap_info_layout">
			<SnapInfo
				snap={$snap_preview}
				project_name={$snap_preview.project_name}
				{is_owner}
				on:edit={handleClickEdit}
			/>
		</div>

		<div class="content_layout">
			{#each $snap_preview.images as image}
				<img src={image.url} alt="" />
			{/each}
		</div>

		<div class="actions_bar_layout">
			<SnapActionsBar snap={$snap_preview} on:clickBack={handleClickBackHistory} />
		</div>
	{/if}
</main>

<!-- Mobile Not Supported -->
{#if $snap_preview.id !== undefined}
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
