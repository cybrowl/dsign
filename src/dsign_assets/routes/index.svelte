<script>
	// import { amp, browser, dev, mode, prerendering } from '$app/env';
	import Header from '../components/Header.svelte';
	import Settings from '../components/Settings.svelte';
	import { isSettingsActive } from '../store/modal';
</script>

<svelte:head>
	<title>DSign</title>
</svelte:head>

<main>
	<html lang="en" class="dark">
		<body class="dark:bg-gray-900 dark:text-gray-200">
			<div class="grid grid-cols-12 gap-2 h-screen">
				<Header />
				{#if $isSettingsActive}
					<Settings />
				{/if}
			</div>
		</body>
	</html>
</main>

<style>
</style>
