<script>
	import { onDestroy } from 'svelte';

	import Modal from 'dsign-components/components/Modal.svelte';
	import ProjectCreation from 'dsign-components/components/ProjectCreation.svelte';
	import ProjectCreationFetching from 'dsign-components/components/ProjectCreationFetching.svelte';

	import { actor_project_main } from '$stores_ref/actors';
	import { local_storage_projects } from '$stores_ref/local_storage';
	import { project_store } from '$stores_ref/fetch_store';
	import modal_update from '$stores_ref/modal';

	let is_creating_project = false;

	onDestroy(() => (is_creating_project = false));

	function handleCloseProjectModal() {
		modal_update.change_visibility('project_creation');
	}

	async function handleCreateProjectSubmit(e) {
		const { project_name } = e.detail;

		is_creating_project = true;

		try {
			const created_project_res = await $actor_project_main.actor.create_project(project_name, []);

			const { ok: all_projects, err: error } = await $actor_project_main.actor.get_all_projects([]);

			if (all_projects) {
				project_store.set({ isFetching: false, projects: [...all_projects] });
				local_storage_projects.set({ all_projects_count: all_projects.length || 1 });
			}

			modal_update.change_visibility('project_creation');
		} catch (error) {
			await $actor_project_main.actor.create_user_project_storage();

			//todo: navigate to error page since call isn't working at all
			console.log('call => handleCreateProjectSubmit error: ', error);
		}
	}
</script>

<Modal
	on:closeModal={handleCloseProjectModal}
	modalHeaderVisible={!is_creating_project}
	isModalLocked={is_creating_project}
>
	{#if is_creating_project === true}
		<ProjectCreationFetching />
	{:else}
		<ProjectCreation on:createProject={handleCreateProjectSubmit} />
	{/if}
</Modal>

<style>
</style>
