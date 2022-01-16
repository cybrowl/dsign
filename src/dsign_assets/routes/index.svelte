<script>
	import { ping } from '../api/profile';

	let responses = [];

	async function handleClick() {
		const pingResponse = await ping();
		responses = [...responses, pingResponse];
	}
</script>

<main>
	<a href="https://dsign.ic" target="_blank" rel="noopener noreferrer" class="logo">
		<img src="/dfinity.svg" alt="DFINITY logo" />
	</a>

	<div>
		<img src="/mishicat.png" alt="MishiCat" on:click={handleClick} />
	</div>

	<h1>Mishicat</h1>

	<h1 class="text-3xl text-red-700 font-bold underline">Map</h1>

	<div>
		<ul>
			{#each responses as response}
				<li>
					{response}
				</li>
			{/each}
		</ul>
	</div>
</main>

<style>
</style>
