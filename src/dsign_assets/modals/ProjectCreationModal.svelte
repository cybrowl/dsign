<script>
	import { onMount, onDestroy } from 'svelte';
	import { goto } from '$app/navigation';
	import { get } from 'lodash';

	import Modal from 'dsign-components/components/Modal.svelte';
	import ProjectCreation from 'dsign-components/components/ProjectCreation.svelte';
	import ProjectCreationFetching from 'dsign-components/components/ProjectCreationFetching.svelte';

	import { actor_project_main } from '$stores_ref/actors';
	import { auth_project_main } from '$stores_ref/auth_client';
	import { navigate_to_home_with_notification } from '$stores_ref/page_navigation';
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

				const id = get(created_project, 'id', null);
				const canister_id = get(created_project, 'canister_id', null);

				if (id && canister_id) {
					goto(`/project/${id}?canister_id=${canister_id}`);
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
