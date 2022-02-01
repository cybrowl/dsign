<script>
	import { isSettingsActive } from '../store/modal';

	function handleSettingsModal() {
		isSettingsActive.update((isSettingsActive) => !isSettingsActive);
	}
</script>

<!-- svelte-ignore a11y-missing-attribute -->
<a on:click={handleSettingsModal}>
	<img alt="avatar" class="rounded-full w-20" src="/mishi-octopus.png" />
</a>

<style>
</style>
