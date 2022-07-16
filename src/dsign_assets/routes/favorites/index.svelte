<!-- src/routes/favorites.svelte -->
<script>
	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../modals/AccountSettingsModal.svelte';
	import Header from '../../components/Header.svelte';
	import SnapCreationModal from '../../modals/SnapCreationModal.svelte';

	import {
		isAccountSettingsModalVisible,
		isAccountCreationModalVisible,
		isSnapCreationModalVisible
	} from '../../store/modal';
</script>

<svelte:head>
	<title>Favorites</title>
</svelte:head>

<main>
	<html lang="en" class="dark">
		<body class="h-screen dark:bg-backdrop dark:text-gray-200">
			<div class="grid grid-cols-12 gap-2">
				<div class="col-start-2 col-end-12 mb-24">
					<Header />
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
			</div>
		</body>
	</html>
</main>

<style>
</style>
