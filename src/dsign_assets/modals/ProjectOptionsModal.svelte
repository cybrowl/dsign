<script>
	import Modal from 'dsign-components/components/Modal.svelte';
	import ProjectOptionsDelete from 'dsign-components/components/ProjectOptionsDelete.svelte';

	// actors
	import { actor_project_main, project_store } from '../store/actor_project_main';

	import { isProjectOptionsModalVisible } from '../store/modal';

	export let project = {};

	function handleCloseModal() {
		isProjectOptionsModalVisible.update(
			(isProjectOptionsModalVisible) => !isProjectOptionsModalVisible
		);
	}

	async function handleDeleteProject() {
		project_store.update(({ projects }) => {
			const updated_projects = projects.filter((project_) => {
				return project_.id !== project.id;
			});

			return {
				isFetching: false,
				projects: updated_projects
			};
		});

		isProjectOptionsModalVisible.update(
			(isProjectOptionsModalVisible) => !isProjectOptionsModalVisible
		);

		const { ok: success, err: error } = await $actor_project_main.actor.delete_projects([
			project.id
		]);
	}
</script>

<Modal on:closeModal={handleCloseModal}>
	<ProjectOptionsDelete on:clickDelete={handleDeleteProject} project_name={project.name} />
</Modal>

<style>
</style>
