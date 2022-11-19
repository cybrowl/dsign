<script>
	import AccountCreationModal from '../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../modals/AccountSettingsModal.svelte';
	import Login from '../components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapCreationModal from '../modals/SnapCreationModal.svelte';

	import { modal_visible } from '../store/modal';
	import { page_navigation } from '../store/page_navigation';

	page_navigation.update(({ navItems }) => {
		navItems.forEach((navItem) => {
			navItem.isSelected = false;
		});
		navItems[0].isSelected = true;

		return {
			navItems: navItems
		};
	});
</script>

<!-- Explore -->
<svelte:head>
	<title>DSign</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 relative">
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
</main>

<!-- Mobile Not Supported -->
<div class="grid lg:hidden h-screen place-items-center text-white text-4xl">
	<h1>Sorry, Mobile Not Supported</h1>
</div>

<style>
</style>
