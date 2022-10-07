<script>
	import MoveSnaps from 'dsign-components/components/MoveSnaps.svelte';
	import CreateProject from 'dsign-components/components/CreateProject.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';

	import { isMoveSnapsModalVisible } from '../store/modal';

	export let projects = [];
	export let number_snaps_selected = 0;
	export let create_project = false;

	function handleMoveSubmit(e) {
		console.log('move submit: ', e.detail);
	}

	function handleCreateProject() {
		create_project = true;
	}

	function handleCloseMoveSnapsModal() {
		isMoveSnapsModalVisible.update((isMoveSnapsModalVisible) => !isMoveSnapsModalVisible);
	}

	function handleCloseProjectModal() {
		create_project = false;
	}
</script>

<div>
	<Modal on:closeModal={handleCloseMoveSnapsModal}>
		<MoveSnaps
			{projects}
			{number_snaps_selected}
			on:moveSubmit={handleMoveSubmit}
			on:createProject={handleCreateProject}
		/>
	</Modal>
	{#if create_project}
		<Modal on:closeModal={handleCloseProjectModal}>
			<CreateProject {projects} {number_snaps_selected} on:moveSubmit={handleMoveSubmit} />
		</Modal>
	{/if}
</div>

<style>
</style>
