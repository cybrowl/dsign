<script>
	import { onMount } from 'svelte';

	import Modal from 'dsign-components/components/Modal.svelte';
	import ProjectRename from 'dsign-components/components/ProjectRename.svelte';

	import { actor_project_main } from '$stores_ref/actors';
	import { auth_project_main } from '$stores_ref/auth_client';
	import { project_store, projects_update } from '$stores_ref/fetch_store';
	import modal_update from '$stores_ref/modal';

	export let project = {};

	onMount(async () => {
		await auth_project_main();
	});

	function handleCloseModal() {
		modal_update.change_visibility('project_rename');
	}

	async function handleRenameProjectSubmit(e) {
		const { project_name } = e.detail;

		if ($actor_project_main.loggedIn) {
			projects_update.rename_project(project, project_name);

			modal_update.change_visibility('project_rename');

			let project_ref = {
				id: project.id,
				canister_id: project.canister_id
			};

			let { ok: updated_project, err: err_update_project_details } =
				await $actor_project_main.actor.update_project_details(
					{ name: [project_name] },
					project_ref
				);

			const { ok: all_projects, err: err_get_all_projects } =
				await $actor_project_main.actor.get_all_projects([]);

			if (all_projects) {
				project_store.set({ isFetching: false, projects: [...all_projects] });
			}
		}
	}
</script>

<Modal on:closeModal={handleCloseModal}>
	<ProjectRename on:renameProject={handleRenameProjectSubmit} />
</Modal>

<style>
</style>
