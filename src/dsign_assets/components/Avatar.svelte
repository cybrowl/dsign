<script>
	import { modal } from '../store/modal';

	function handleSettingsModal() {
		modal.update(() => ({
			isSettingsActive: true
		}));
	}
</script>

<!-- svelte-ignore a11y-missing-attribute -->
<a on:click={handleSettingsModal}>
	<img alt="avatar" class="rounded-full w-20" src="/mishi-octopus.png" />
</a>

<style>
</style>
