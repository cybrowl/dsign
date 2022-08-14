<!-- src/routes/profile.svelte -->
<script>
	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../modals/AccountSettingsModal.svelte';
	import Login from '../../components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import SnapCreationModal from '../../modals/SnapCreationModal.svelte';

	import {
		isAccountSettingsModalVisible,
		isAccountCreationModalVisible,
		isSnapCreationModalVisible
	} from '../../store/modal';
	import { page_navigation } from '../../store/page_navigation';

	page_navigation.update(({ navItems }) => {
		navItems.forEach((navItem) => {
			navItem.isSelected = false;
		});
		navItems[3].isSelected = true;

		return {
			navItems: navItems
		};
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
	{#if $isAccountSettingsModalVisible}
		<AccountSettingsModal />
	{/if}

	<!-- AccountCreationModal -->
	{#if $isAccountCreationModalVisible}
		<AccountCreationModal />
	{/if}

	<!-- SnapCreationModal -->
	{#if $isSnapCreationModalVisible}
		<SnapCreationModal />
	{/if}

	<div class="h-screen" />
</main>

<style>
</style>
