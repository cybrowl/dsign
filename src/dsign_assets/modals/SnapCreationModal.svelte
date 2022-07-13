<script>
	import SnapCreation from 'dsign-components/components/SnapCreation.svelte';
	import get from 'lodash/get.js';
	import Modal from 'dsign-components/components/Modal.svelte';

	// import { createActor as create_actor_username, actor_username } from '../store/actor_username';


	import { isSnapCreationModalVisible } from '../store/modal';


	function handleCloseModal() {
		isSnapCreationModalVisible.update(
			(isSnapCreationModalVisible) => !isSnapCreationModalVisible
		);
	}

</script>

<Modal on:closeModal={handleCloseModal}>
	<SnapCreation />
</Modal>

<style>
</style>
