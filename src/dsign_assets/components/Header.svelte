<script>
	import Login from './Login.svelte';
</script>

<div class="col-span-12">
	<div class="flex flex-row justify-between items-center m-6">
		<nav class="flex items-center">
			<a href="/" class="mr-12 text-4xl font-bold">DSign</a>
			<a href="/" class="mr-8 font-medium hover:underline">Explore</a>
			<a href="/projects" class="mr-8 font-medium hover:underline">Projects</a>
			<a href="/favorites" class="mr-8 font-medium hover:underline">Favorites</a>
		</nav>
		<Login />
	</div>
</div>

<style>
</style>
