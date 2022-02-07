<script>
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';
	import { profileManager } from '../store/profile_manager';

	let hasAccountPromise = $profileManager.actor.has_account();
	let hasAccount = false;

	(async () => {
		hasAccount = await hasAccountPromise;
	})();

	console.log('hasAccount: ', hasAccount);

	async function handleSettingsModal() {
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
