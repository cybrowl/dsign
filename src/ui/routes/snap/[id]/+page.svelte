<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { get, isEmpty } from 'lodash';

	import Login from '$components_ref/Login.svelte';
	import { SnapActionsBar, PageNavigation, SnapInfo } from 'dsign-components';
	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';

	import { auth, init_auth } from '$stores_ref/auth_client';
	import { actor_creator } from '$stores_ref/actors';
	import { snap_preview_store, snap_project_store, snap_upsert_store } from '$stores_ref/data_snap';

	import { modal_visible } from '$stores_ref/modal';
	import { page_navigation } from '$stores_ref/page_navigation';

	const snap_cid = $page.url.searchParams.get('cid');
	const snap_id = $page.url.pathname.split('/').pop();

	onMount(async () => {
		try {
			await init_auth();
			await auth.creator(snap_cid);
			const { ok: snap, err: error } = await $actor_creator.actor.get_snap(snap_id);

			snap_preview_store.set({ isFetching: false, snap });
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
		snap_upsert_store.set({ isFetching: false, mode: 'edit', snap: $snap_preview_store.snap });

		goto(`/snap/edit`);
	}

	async function goto_feedback(event) {
		await auth.creator(snap_cid);

		if ($actor_creator.loggedIn) {
			const project_id = get($snap_preview_store, 'snap.project_id', '');

			const { ok: topic, err: error } = await $actor_creator.actor.create_feedback_topic({
				project_id: project_id,
				snap_id: snap_id
			});

			console.log('topic: ', topic);

			debugger;

			// goto(`/project/${project.name}?id=${project.id}&cid=${project.canister_id}&tab=feedback`);
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
	{#if $snap_preview_store.snap.id !== undefined}
		<div class="snap_info_layout">
			<SnapInfo
				snap={$snap_preview_store.snap}
				project_name={get($snap_project_store, 'project.name', '')}
				is_owner={get($snap_preview_store, 'snap.is_owner', '')}
				on:edit={goto_edit_snap}
			/>
		</div>

		<div class="content_layout">
			{#each $snap_preview_store.snap.images as image}
				<img src={image.url} alt="" />
			{/each}
		</div>

		<div class="actions_bar_layout">
			<SnapActionsBar
				snap={$snap_preview_store.snap}
				is_authenticated={$actor_creator.loggedIn}
				on:clickBack={go_back_history}
				on:clickFeedback={goto_feedback}
			/>
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
