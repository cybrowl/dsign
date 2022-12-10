<script lang="js">
	import '../app.css';
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';

	import { auth_client } from '$stores_ref/auth_client';

	onMount(async () => {
		const authClient = await AuthClient.create();

		auth_client.set(authClient);
	});
</script>

<slot />

<style lang="postcss">
</style>
