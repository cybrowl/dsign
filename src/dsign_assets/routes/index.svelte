<script>
	// import { amp, browser, dev, mode, prerendering } from '$app/env';
	import Header from '../components/Header.svelte';
	import Settings from '../components/Settings.svelte';
	import { modal } from '../store/modal';
</script>

<svelte:head>
	<title>DSign</title>
</svelte:head>

<main>
	<html lang="en" class="dark">
		<body class="dark:bg-gray-800 dark:text-gray-200">
			<Header />
			{#if $modal.isSettingsActive}
				<Settings />
			{/if}
		</body>
	</html>
</main>

<style>
</style>
