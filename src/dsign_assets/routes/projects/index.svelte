<!-- src/routes/projects.svelte -->
<svelte:head>
	<title>Projects</title>
</svelte:head>

<script>
	// import { amp, browser, dev, mode, prerendering } from '$app/env';
	import AccountCreation from '../../components/AccountCreation.svelte';
	import Header from '../../components/Header.svelte';
	import Settings from '../../components/Settings.svelte';
	import { isSettingsActive, isAccountCreationActive } from '../../store/modal';
</script>

<main>
	<html lang="en" class="dark">
		<body class="h-screen dark:bg-backdrop dark:text-gray-200">
			<div class="grid grid-cols-12 gap-2">
				<Header />
				{#if $isSettingsActive}
					<Settings />
				{/if}
				{#if $isAccountCreationActive}
					<AccountCreation />
				{/if}
			</div>
		</body>
	</html>
</main>

<style>
</style>
