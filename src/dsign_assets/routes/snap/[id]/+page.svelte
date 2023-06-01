<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { get, last, isEmpty } from 'lodash';
	import { replacer, reviver } from '$utils/big_int';

	import Login from '$components_ref/Login.svelte';
	import { SnapActionsBar, PageNavigation, SnapInfo } from 'dsign-components';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { actor_snap_main, actor_profile } from '$stores_ref/actors';
	import { auth_profile } from '$stores_ref/auth_client';
	import { disable_project_store_reset } from '$stores_ref/page_state';
	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation, snap_creation, snap_preview } from '$stores_ref/page_navigation';
	import { local_snap_creation } from '$stores_ref/local_storage';

	disable_project_store_reset.set(true);

	let is_owner = false;

	onMount(async () => {
		const canister_id = $page.url.searchParams.get('canister_id');
		const snap_id = last(get($page, 'url.pathname', '').split('/'));

		await Promise.all([auth_profile()]);

		try {
			if ($snap_preview.id === undefined) {
				const { ok: snap } = await $actor_snap_main.actor.get_snap(snap_id, canister_id);

				snap_preview.update(() => ({
					...snap
				}));

				console.log('$snap_preview,: ', $snap_preview);

				// goto('/snap/' + snap.id + '?canister_id=' + snap.canister_id);
			}

			if ($actor_profile.loggedIn) {
				//TODO: maybe get it from localstorage
				const { ok: profile } = await $actor_profile.actor.get_profile();
				const username = get(profile, 'username', 'x');
				let snap_username = get($snap_preview, 'username', '');

				if (snap_username === username) {
					is_owner = true;
				}
			}
		} catch (error) {
			console.log('error snap preview: ', error);
		}
	});

	function handleClickBackHistory() {
		const project_id = get($snap_preview, 'project.id', '');
		const project_canister = get($snap_preview, 'project.canister_id', '');
		const project_href = `/project/${project_id}/?canister_id=${project_canister}`;

		if (!isEmpty(project_id)) {
			goto(project_href);
		} else {
			goto(`/${$snap_preview.username}`);
		}
	}

	function handleClickEdit() {
		let project_id = get($snap_preview, 'project.id', '');
		let project_canister = get($snap_preview, 'project.canister_id', '');
		const snap = JSON.parse($local_snap_creation.data, reviver);

		snap_creation.update(() => ({
			...$snap_preview
		}));

		if (isEmpty(project_id)) {
			project_id = snap.project.id;
			project_canister = snap.project.canister_id;
		}

		const snap_preview_seralized = JSON.stringify($snap_preview, replacer);

		local_snap_creation.set({
			data: snap_preview_seralized
		});

		if (project_id) {
			// goto(`/snap/upsert?project_id=${project_id}&canister_id=${project_canister}&mode=edit`);
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
			<SnapInfo snap={$snap_preview} {is_owner} on:edit={handleClickEdit} />
		</div>

		<div class="row-start-3 row-end-auto col-start-1 col-end-12 mb-10 flex flex-col items-center">
			{#each $snap_preview.images as image}
				<img src={image.url} alt="" class="pb-10 max-w-full" />
			{/each}
		</div>

		<div class="row-start-3 row-end-auto col-start-12 col-end-13 mb-10 flex justify-center">
			<SnapActionsBar snap={$snap_preview} on:clickBack={handleClickBackHistory} />
		</div>
	{/if}
</main>
