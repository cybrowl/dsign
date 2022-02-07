<script>
	import { isSettingsActive, isAccountCreationActive } from '../store/modal';
	import { profileManager } from '../store/profile_manager';
	import { profileStorage } from '../store/local_storage';

	let hasAccount = false;
	let hasUsername = $profileStorage.username.length > 0 || false;

	let hasAccountPromise = $profileManager.actor.has_account();
	let profilePromise = $profileManager.actor.get_profile();

	(async () => {
		hasAccount = await hasAccountPromise;

		if (!hasUsername) {
			let profileRes = await profilePromise;
			let username = profileRes.ok.username;

			profileStorage.set({ username });
		}
	})();

	async function handleSettingsModal() {
		//TODO: add local storage cache instead of making call
		if (hasAccount) {
			isSettingsActive.update((isSettingsActive) => !isSettingsActive);
		} else {
			isAccountCreationActive.update((isAccountCreationActive) => !isAccountCreationActive);
		}
	}
</script>

<!-- <img
	alt="avatar"
	class="rounded-full w-20"
	src="/mishi-octopus.png"
	on:click={handleSettingsModal}
/> -->
<div
	class="m-2 mr-2 w-16 h-16 flex justify-center items-center rounded-full bg-indigo-800 text-xl text-white uppercase"
	on:click={handleSettingsModal}
>
	<p>
		{$profileStorage.username.charAt(0)}
		{$profileStorage.username.charAt($profileStorage.username.length - 1)}
	</p>
</div>

<style>
</style>
