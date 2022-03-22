<script>
	// import { amp, browser, dev, mode, prerendering } from '$app/env';
	import AccountCreation from '../components/AccountCreation.svelte';
	import Header from '../components/Header.svelte';
	// import Settings from '../components/Settings.svelte';
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';
</script>

<svelte:head>
	<title>DSign</title>
</svelte:head>

<main>
	<html lang="en" class="dark">
		<body class="dark:bg-backdrop dark:text-gray-200">
			<div class="grid grid-cols-12 gap-2">
				<!-- <Header /> -->
				{#if $isSettingsActive}
					<!-- <Settings /> -->
				{/if}
				{#if $isAccountCreationActive}
					<!-- <AccountCreation /> -->
				{/if}
			</div>
		</body>
	</html>
</main>

<style>
</style>
