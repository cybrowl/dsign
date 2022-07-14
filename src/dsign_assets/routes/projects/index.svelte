<script>
	import {
		isAccountSettingsModalVisible,
		isAccountCreationModalVisible,
		isSnapCreationModalVisible
	} from '../../store/modal';
	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../modals/AccountSettingsModal.svelte';
	import SnapCreationModal from '../../modals/SnapCreationModal.svelte';
	import Header from '../../components/Header.svelte';
</script>

<!-- src/routes/projects.svelte -->
<svelte:head>
	<title>Projects</title>
</svelte:head>

<main>
	<html lang="en" class="dark">
		<body class="h-screen dark:bg-backdrop dark:text-gray-200">
			<div class="grid grid-cols-12 gap-2">
				<Header />
				{#if $isAccountSettingsModalVisible}
					<AccountSettingsModal />
				{/if}
				{#if $isAccountCreationModalVisible}
					<AccountCreationModal />
				{/if}
				{#if $isSnapCreationModalVisible}
					<SnapCreationModal />
				{/if}
			</div>
		</body>
	</html>
</main>

<style>
</style>
