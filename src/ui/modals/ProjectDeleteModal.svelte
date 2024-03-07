<script>
	import { onMount } from 'svelte';

	import { ProjectDelete, Modal } from 'dsign-components';

	import { actor_creator } from '$stores_ref/actors';
	import { auth } from '$stores_ref/auth_client';
	import { navigate_to_home_with_notification } from '$stores_ref/page_navigation';
	import { projects_update } from '$stores_ref/fetch_store';
	import modal_update, { modal_mode } from '$stores_ref/modal';

	onMount(async () => {
		await Promise.all([auth.snap_main(), auth.project_main()]);
	});

	function handleCloseModal() {
		modal_update.change_visibility('project_delete');
	}

	async function handleDeleteProject() {
		const project = get($modal_mode, 'project', '');

		if ($actor_creator.loggedIn) {
			try {
				//TODO: delete images & files assoc with snaps
				//TODO: delete snaps
				//TODO: delete project
				modal_update.change_visibility('project_delete');
			} catch (error) {
				console.log(error);
			}
		} else {
			navigate_to_home_with_notification();
		}
	}
</script>

<Modal on:closeModal={handleCloseModal}>
	<ProjectDelete on:delete={handleDeleteProject} project_name={project.name} />
</Modal>

<style>
</style>
