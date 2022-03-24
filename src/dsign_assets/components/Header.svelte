<script>
	import Login from './Login.svelte';
	import Button from 'dsign-components/components/Button.svelte';
</script>

<div class="col-span-12 m-10">
	<div class="">
		<nav>
			<a href="#_" class="mr-5 font-large uppercase">DSign</a>
			<a href="#_" class="mr-5 font-medium hover:underline">Explore</a>
			<a href="#_" class="mr-5 font-medium hover:underline">Projects</a>
			<a href="#_" class="mr-5 font-medium hover:underline">Favorites</a>
		</nav>
	</div>
	<div class="flex justify-end justify-items-end">
		<Button label="Upload" primary={true} class="mr-4" />
		<Login />
	</div>
</div>

<style>
</style>
