<script>
	import Modal from 'dsign-components/components/Modal.svelte';
	import ProjectOptionsDelete from 'dsign-components/components/ProjectOptionsDelete.svelte';

	// actors
	import { actor_project_main, project_store } from '../store/actor_project_main';
	import { actor_snap_main } from '../store/actor_snap_main';

	import { is_project_options_modal_visible } from '../store/modal';

	export let project = {
		snaps: []
	};

	function handleCloseModal() {
		is_project_options_modal_visible.update(
			(is_project_options_modal_visible) => !is_project_options_modal_visible
		);
	}

	async function handleDeleteProject() {
		const project_snaps_ids = project.snaps.map((snap) => snap.id);

		project_store.update(({ projects }) => {
			const updated_projects = projects.filter((project_) => {
				return project_.id !== project.id;
			});

			return {
				isFetching: false,
				projects: updated_projects
			};
		});

		is_project_options_modal_visible.update(
			(is_project_options_modal_visible) => !is_project_options_modal_visible
		);

		try {
			const { ok: success, err: error } = await $actor_project_main.actor.delete_projects([
				project.id
			]);

			const { ok: deleted_snaps, err: deleted_snaps_err } =
				await $actor_snap_main.actor.delete_snaps(project_snaps_ids);
		} catch (error) {
			console.log(error);
		}
	}
</script>

<Modal on:closeModal={handleCloseModal}>
	<ProjectOptionsDelete on:clickDelete={handleDeleteProject} project_name={project.name} />
</Modal>

<style>
</style>
