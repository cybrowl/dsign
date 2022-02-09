<script>
	import { fade, fly } from 'svelte/transition';
	import { isSettingsActive } from '../store/modal';
	import { profileStorage } from '../store/local_storage';
	import { profileManager } from '../store/profile_manager';
	import Logout from './Logout.svelte';

	let profilePromise = $profileManager.actor.get_profile();
	let username = $profileStorage.username;
	let files;

	function handleSettingsModal() {
		isSettingsActive.update((isSettingsActive) => !isSettingsActive);
	}
</script>

<div
	class="fixed top-0 left-0 right-0 h-full w-full bg-dark-stone opacity-90"
	on:click={handleSettingsModal}
/>
<div class="fade fixed top-40 left-1/4 right-1/4" in:fly={{ y: 200, duration: 1000 }} out:fade>
	<div class="bg-white rounded-lg shadow dark:bg-gray-700">
		<div class="z-0">
			<div class="flex justify-between items-start p-5 rounded-t">
				<button
					type="button"
					class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center dark:hover:bg-gray-600 dark:hover:text-white"
					on:click={handleSettingsModal}
				>
					<svg
						class="w-5 h-5"
						fill="currentColor"
						viewBox="0 0 20 20"
						xmlns="http://www.w3.org/2000/svg"
						><path
							fill-rule="evenodd"
							d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
							clip-rule="evenodd"
						/></svg
					>
				</button>
			</div>
		</div>
		<div class="relative h-96">
			<div
				class="m-2 ml-8 mr-2 w-16 h-16 flex justify-center items-center rounded-full bg-indigo-800 text-xl text-white uppercase cursor-pointer"
				on:click={() => {}}
			>
				<p class="cursor-pointer">
					{$profileStorage.username.charAt(0)}
					{$profileStorage.username.charAt($profileStorage.username.length - 1)}
				</p>
			</div>
			<input type="file" bind:files />
			{console.info('files: ', files)}
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
</style>
