<script>
	import Login from './Login.svelte';
</script>

<div class="col-span-12">
	<div class="flex flex-row justify-between items-center m-6">
		<div class="">
			<nav>
				<a href="/" class="mr-5 font-large uppercase">DSign</a>
				<a href="/" class="mr-5 font-medium hover:underline">Explore</a>
				<a href="/projects" class="mr-5 font-medium hover:underline">Projects</a>
				<a href="/favorites" class="mr-5 font-medium hover:underline">Favorites</a>
			</nav>
		</div>
		<Login />
	</div>
</div>

<style>
</style>
