<script>
	import { isAccountCreationActive } from '../store/modal';
	import { profileManager } from '../store/profile_manager';

	let username = '';
	let createProfilePromise = null;

	function handleAccountCreation() {
		isAccountCreationActive.update((isAccountCreationActive) => !isAccountCreationActive);
	}

	function handleCreateProfile() {
		createProfilePromise = $profileManager.actor.create_profile(username);
	}
</script>

<div class="fade fixed top-40 left-80 right-80">
	<div class="bg-white rounded-lg shadow dark:bg-gray-700">
		<div class="">
			<div class="flex justify-between items-start p-5 rounded-t">
				<button
					type="button"
					class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center dark:hover:bg-gray-600 dark:hover:text-white"
					on:click={handleAccountCreation}
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
			<div class="grid grid-cols-3">
				<div />
				<div class="flex flex-col gap-y-20">
					<h1>Create an account</h1>
					<input class="text-xl font-medium text-black" bind:value={username} />
					<a href="#_">Privacy Policy</a>
					<div class="create account">
						{#await createProfilePromise}
						  creating account
						{:then response}
						  <code>{JSON.stringify(response)}</code>
						{/await}
					  </div>
				</div>
				<div />
			</div>
			<div
				class="absolute bottom-0 right-0 m-5 bg-indigo-800 hover:bg-indigo-900 text-white py-2 px-4 rounded"
			>
				<button on:click={handleCreateProfile}>Create Account</button>
			</div>
		</div>
	</div>
</div>

<style>
</style>
