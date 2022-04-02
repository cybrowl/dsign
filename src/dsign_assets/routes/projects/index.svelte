<!-- src/routes/projects.svelte -->
<svelte:head>
	<title>Projects</title>
</svelte:head>

<script>
	import { isAccountSettingsModalVisible, isAccountCreationModalVisible } from '../../store/modal';
	import AccountCreationModal from '../../components/AccountCreationModal.svelte';
	import AccountSettingsModal from '../../components/AccountSettingsModal.svelte';
	import Header from '../../components/Header.svelte';
</script>

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
			</div>
		</body>
	</html>
</main>

<style>
</style>
