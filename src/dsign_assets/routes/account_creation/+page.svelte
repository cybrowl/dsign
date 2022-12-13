<script>
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import Login from '../../components/Login.svelte';

	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';

	import { page_navigation } from '$stores_ref/page_navigation';
</script>

<svelte:head>
	<title>Account Creation</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-24">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	<AccountCreationModal />

	<div class="h-screen" />
</main>

<style>
</style>
