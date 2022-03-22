<script>
	import { isAccountCreationActive } from '../store/modal';
	import { profileManager } from '../store/profile_manager';
	import Modal from "dsign-components/components/Modal.svelte";
	import CreateUsername from "dsign-components/components/CreateUsername.svelte";

	let createProfilePromise = null;

	function handleAccountCreation() {
		isAccountCreationActive.update((isAccountCreationActive) => !isAccountCreationActive);
	}

	function handleCreateProfile() {
		createProfilePromise = $profileManager.actor.create_profile(e.detail.username);
	}
</script>

<Modal>
	<CreateUsername on:click={handleCreateProfile} />
</Modal>

<style>
</style>
