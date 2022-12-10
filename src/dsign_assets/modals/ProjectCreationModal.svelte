<script>
	import { onMount, onDestroy } from 'svelte';

	import Modal from 'dsign-components/components/Modal.svelte';
	import ProjectCreation from 'dsign-components/components/ProjectCreation.svelte';
	import ProjectCreationFetching from 'dsign-components/components/ProjectCreationFetching.svelte';

	import { actor_project_main } from '$stores_ref/actors';
	import { auth_project_main } from '$stores_ref/auth_client';
	import { local_storage_projects } from '$stores_ref/local_storage';
	import { navigate_to_home_with_notification } from '$stores_ref/page_navigation';
	import { project_store } from '$stores_ref/fetch_store';
	import modal_update from '$stores_ref/modal';

	let is_creating_project = false;

	onMount(async () => {
		await auth_project_main();
	});

	onDestroy(() => (is_creating_project = false));

	function handleCloseProjectModal() {
		modal_update.change_visibility('project_creation');
	}

	async function handleCreateProjectSubmit(e) {
		const { project_name } = e.detail;

		is_creating_project = true;

		if ($actor_project_main.loggedIn) {
			try {
				const { ok: created_project, err: err_create_project } =
					await $actor_project_main.actor.create_project(project_name, []);

				const { ok: all_projects, err: err_get_all_projects } =
					await $actor_project_main.actor.get_all_projects([]);

				if (all_projects) {
					project_store.set({ isFetching: false, projects: [...all_projects] });
					local_storage_projects.set({ all_projects_count: all_projects.length || 1 });
				}

				modal_update.change_visibility('project_creation');
			} catch (error) {
				//TODO: log error
			}
		} else {
			navigate_to_home_with_notification();
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
