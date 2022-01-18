<script>
	import { ping, get_canister_caller_principal } from '../api/profile';
	import { amp, browser, dev, mode, prerendering } from '$app/env';

	let responses = ['first'];

	if (browser) {
		Promise.all([ping(), get_canister_caller_principal()]).then((values) => {
			responses = [...responses, values];
		});
	}

	async function onLogin() {}
</script>

<svelte:head>
	<title>Welcome</title>
</svelte:head>

<main>
	<div class="grid grid-cols-2 gap-2">
		<div>
			<h1>MishiCat</h1>
		</div>

		<div>
			<img src="/mishi-octopus.png" alt="MishiCat" class="w-80" />
		</div>

		<div>
			<button
				class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
				on:click={onLogin}
			>
				Login
			</button>
		</div>

		<div>
			<ul>
				{#each responses as response}
					<li>
						{response}
					</li>
				{/each}
			</ul>
		</div>
	</div>
</main>

<style>
</style>
