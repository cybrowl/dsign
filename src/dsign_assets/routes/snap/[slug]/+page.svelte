<script>
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import get from 'lodash/get';
	import last from 'lodash/last';

	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapPreview from 'dsign-components/components/SnapPreview.svelte';
	import Icon from 'dsign-components/components/Icon.svelte';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { actor_snap_main } from '$stores_ref/actors';
	import modal_update, { modal_visible } from '$stores_ref/modal';
	import page_navigation_update, {
		page_navigation,
		snap_preview
	} from '$stores_ref/page_navigation';

	page_navigation_update.deselect_all();

	// isEmpty($project_store_public.project) === true && project_store_public_fetching();

	onMount(async () => {
		const canister_id = $page.url.searchParams.get('canister_id');
		const snap_id = last(get($page, 'url.pathname', '').split('/'));

		try {
			const { ok: snap } = await $actor_snap_main.actor.get_snap(snap_id, canister_id);

			snap_preview.set(snap);
		} catch (error) {
			console.log('error projects: ', error);
		}
	});
</script>

<svelte:head>
	<title>Snap</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-8">
		<PageNavigation navigationItems={$page_navigation.navigationItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- Modals -->

	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<div class="col-start-2 col-end-12 row-start-2 row-end-auto mb-20">
		<div class="close" on:click={() => history.back()} on:keypress={console.log('todo')}>
			<Icon class="closeRounded" name="close_rounded" width="48" height="48" />
		</div>
		{#if $snap_preview.id !== undefined}
			<SnapPreview snap={$snap_preview} />
		{/if}
	</div>
</main>

<style>
	.close {
		margin-right: 12%;
		position: absolute;
		right: 0;
	}
</style>
