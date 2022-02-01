<script>
	import { isSettingsActive } from '../store/modal';

	function handleSettingsModal() {
		isSettingsActive.update((isSettingsActive) => !isSettingsActive);
	}
</script>

<img
	alt="avatar"
	class="rounded-full w-20"
	src="/mishi-octopus.png"
	on:click={handleSettingsModal}
/>

<style>
</style>
