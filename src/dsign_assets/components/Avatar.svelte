<script>
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';
	import { profileManager } from '../store/profile_manager';

	async function handleSettingsModal() {
		let hasAccountPromise = $profileManager.actor.has_account();
		let hasAccount = await hasAccountPromise;

		//TODO: add local storage cache instead of making call

		if (hasAccount) {
			isSettingsActive.update((isSettingsActive) => !isSettingsActive);
		} else {
			isAccountCreationActive.update((isAccountCreationActive) => !isAccountCreationActive);
		}
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
