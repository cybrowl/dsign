<!-- <script>
	import { fade, fly } from 'svelte/transition';
	import { isSettingsActive } from '../store/modal';
	import { profileStorage } from '../store/local_storage';
	import { profileManager } from '../store/profile_manager';
	import Logout from './Logout.svelte';
	import Icon from './Icon.svelte';
	import _ from 'lodash';

	let hasAvatar = $profileStorage.avatar.length > 3 || false;
	let profilePromise = $profileManager.actor.get_profile();
	let username = $profileStorage.username;
	let files;
	let count = 0;

	function handleSettingsModal() {
		isSettingsActive.update((isSettingsActive) => !isSettingsActive);
	}

	async function handleAvatarChange() {
		const selectedFile = files[0];

		const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
		const avatar = {
			content: [...imageAsUnit8ArrayBuffer]
		};

		await $profileManager.actor.set_avatar(avatar);
		let { ok: profile } = await $profileManager.actor.get_profile();

		count++;

		profileStorage.set({
			avatar: _.get(profile, 'avatar', '') + '&' + count,
			username: _.get(profile, 'username', ''),
			website: ''
		});
	}
</script>

<div
	class="fixed top-0 left-0 right-0 h-full w-full bg-backdrop opacity-90"
	on:click={handleSettingsModal}
/>
<div class="fade fixed top-40 left-1/4 right-1/4" in:fly={{ y: 200, duration: 1000 }} out:fade>
	<div class="bg-white rounded-lg shadow dark:bg-dark-grey">
		<div class="z-0">
			<div class="flex justify-between items-start p-5 rounded-t">
				<button
					type="button"
					class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center dark:hover:bg-gray-600 dark:hover:text-white"
					on:click={handleSettingsModal}
				>
					<Icon name="close_standard" width="20" height="20" />
				</button>
			</div>
		</div>
		<div class="relative h-96">
			<div
				class="m-2 ml-8 mr-2 w-16 h-16 flex justify-center items-center rounded-full 
				bg-black-a text-xl text-white uppercase cursor-pointer"
				on:click={() => {}}
			>
				{#if hasAvatar}
					<img alt="avatar" src={$profileStorage.avatar} />
				{:else}
					<div
						class="m-2 mr-2 w-16 h-16 flex justify-center items-center rounded-full 
				bg-indigo-800 text-xl text-white uppercase cursor-pointer"
						on:click={handleSettingsModal}
					>
						<p class="cursor-pointer">
							{$profileStorage.username.charAt(0)}
							{$profileStorage.username.charAt($profileStorage.username.length - 1)}
						</p>
					</div>
				{/if}
			</div>

			<input type="file" bind:files on:change={handleAvatarChange} />

			<div class="m-10">
				{#if username}
					<h4>Username</h4>
					<p>{username}</p>
				{:else}
					{#await profilePromise}
						<p>...getting profile</p>
					{:then { ok: { username } }}
						<h4>Username</h4>
						<p>{username}</p>
					{:catch error}
						<p style="color: red">{error.message}</p>
					{/await}
				{/if}
			</div>
			<div class="absolute bottom-0 right-0 m-5">
				<Logout />
			</div>
		</div>
	</div>
</div>

<style>
</style> -->
