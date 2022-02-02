<script>
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';

	function handleSettingsModal() {
		isSettingsActive.update((isSettingsActive) => !isSettingsActive);
		isAccountCreationActive.update((isAccountCreationActive) => !isAccountCreationActive);
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
