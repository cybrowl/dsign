<script>
	import { onMount } from 'svelte';

	import { ProjectDelete, Modal } from 'dsign-components-v2';

	import { actor_project_main, actor_snap_main } from '$stores_ref/actors';
	import { auth_snap_main, auth_project_main } from '$stores_ref/auth_client';
	import { navigate_to_home_with_notification } from '$stores_ref/page_navigation';
	import { projects_update } from '$stores_ref/fetch_store';
	import modal_update from '$stores_ref/modal';

	export let project = {
		snaps: []
	};

	onMount(async () => {
		await Promise.all([auth_snap_main(), auth_project_main()]);
	});

	function handleCloseModal() {
		modal_update.change_visibility('project_delete');
	}

	async function handleDeleteProject() {
		if ($actor_project_main.loggedIn && $actor_snap_main.loggedIn) {
			const project_snaps_ids = projects_update.delete_projects(project);

			modal_update.change_visibility('project_delete');

			try {
				const { err: err_delete_projects } = await $actor_project_main.actor.delete_projects([
					project.id
				]);

				const { err: err_delete_snaps } = await $actor_snap_main.actor.delete_snaps(
					project_snaps_ids
				);

				//TODO: handle errors
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
