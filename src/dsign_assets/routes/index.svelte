<script>
	import { ping, get_canister_caller_principal } from '../api/profile';
	import { amp, browser, dev, mode, prerendering } from '$app/env';
	import Auth from '../components/Auth.svelte';

	let responses = [];

	if (browser) {
		Promise.all([ping(), get_canister_caller_principal()]).then((values) => {
			responses = [...responses, ...values];
		});
	}

	async function onLogin() {}
</script>

<svelte:head>
	<title>Welcome</title>
</svelte:head>

<main>
	<Auth />
	<div class="grid grid-cols-2 gap-2">
		<div>
			<h1>MishiCat</h1>
		</div>

		<div>
			<img src="/mishi-octopus.png" alt="MishiCat" class="w-80" />
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
