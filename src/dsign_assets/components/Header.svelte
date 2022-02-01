<script>
	import Login from './Login.svelte';
</script>

<header
	class="dark:bg-gray-800 dark:text-gray-200 w-full mt-5 text-gray-700 shadow-sm body-font"
>
	<div class="container flex flex-col items-start justify-between p-6 mx-auto md:flex-row">
		<!-- svelte-ignore a11y-missing-attribute -->
		<a
			class="relative z-10 flex items-center w-auto text-2xl font-extrabold leading-none text-black select-none"
			>DSign</a
		>
		<nav
			class="flex flex-wrap items-center justify-center pl-6 ml-6 text-base border-l border-gray-200 md:mr-auto"
		>
			<a href="#_" class="mr-5 font-medium hover:text-gray-900">Explore</a>
			<a href="#_" class="mr-5 font-medium hover:text-gray-900">Projects</a>
			<a href="#_" class="font-medium hover:text-gray-900">Favorites</a>
		</nav>
		<div class="items-center h-full">
			<Login />
		</div>
	</div>
</header>

<style>
</style>
