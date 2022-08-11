<script>
	import Login from './Login.svelte';
</script>

<div class="flex flex-row justify-between items-center my-10">
	<nav class="flex items-center text-gray-200 ">
		<a href="/" class="mr-12 text-4xl font-bold">DSign</a>
		<a href="/" class="mr-8 font-medium hover:underline">Explore</a>
		<a href="/projects" class="mr-8 font-medium hover:underline">Projects</a>
		<a href="/collab" class="mr-8 font-medium hover:underline">Collab</a>
		<a href="/favorites" class="mr-8 font-medium hover:underline">Favorites</a>
		<a href="/profile" class="mr-8 font-medium hover:underline">Profile</a>
	</nav>
	<Login />
</div>

<style>
</style>
