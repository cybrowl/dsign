<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import get from 'lodash/get';
	import last from 'lodash/last';

	import Login from '$components_ref/Login.svelte';
	import { SnapActionsBar, PageNavigation, SnapInfo } from 'dsign-components-v2';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { actor_snap_main } from '$stores_ref/actors';
	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation, snap_preview } from '$stores_ref/page_navigation';
	import { disable_project_store_reset } from '$stores_ref/page_state';

	disable_project_store_reset.set(true);

	onMount(async () => {
		const canister_id = $page.url.searchParams.get('canister_id');
		const snap_id = last(get($page, 'url.pathname', '').split('/'));

		console.log('snap_preview: ', $snap_preview);
		try {
			if ($snap_preview.id === undefined) {
				const { ok: snap } = await $actor_snap_main.actor.get_snap(snap_id, canister_id);

				snap_preview.set(snap);
			}
		} catch (error) {
			console.log('error projects: ', error);
		}
	});

	function clickBackHistory() {
		const has_project = get($snap_preview, 'project.id', '').length > 0;
		const project_href = `/project/${get($snap_preview, 'project.id', '')}/?canister_id=${get(
			$snap_preview,
			'project.canister_id',
			''
		)}`;

		if (has_project) {
			goto(project_href);
		} else {
			goto(`/${$snap_preview.username}`);
		}
	}
</script>

<svelte:head>
	<title>Snap</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 ml-12 mr-12">
	<div class="row-start-1 row-end-auto col-start-1 col-end-13">
		<PageNavigation navigationItems={$page_navigation.navigationItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- Modals -->
	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<!-- Snap -->
	{#if $snap_preview.id !== undefined}
		<div class="row-start-2 row-end-auto col-start-1 col-end-13 mb-10">
			<SnapInfo snap={$snap_preview} />
		</div>

		<div class="row-start-3 row-end-auto col-start-1 col-end-12 mb-10 flex flex-col items-center">
			{#each $snap_preview.images as image}
				<img src={image.url} alt="" class="pb-10 max-w-full" />
			{/each}
		</div>

		<div class="row-start-3 row-end-auto col-start-12 col-end-13 mb-10 flex justify-center">
			<SnapActionsBar snap={$snap_preview} on:clickBack={clickBackHistory} />
		</div>
	{/if}
</main>
