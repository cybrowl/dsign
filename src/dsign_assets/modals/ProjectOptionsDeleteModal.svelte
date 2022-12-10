<script>
	import Modal from 'dsign-components/components/Modal.svelte';
	import ProjectOptionsDelete from 'dsign-components/components/ProjectOptionsDelete.svelte';

	import { actor_project_main, actor_snap_main } from '$stores_ref/actors';
	import { modal_visible } from '$stores_ref/modal';
	import { project_store } from '$stores_ref/fetch_store';

	export let project = {
		snaps: []
	};

	function handleCloseModal() {
		modal_visible.update((options) => {
			return {
				...options,
				project_options: !options.project_options
			};
		});
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

		modal_visible.update((options) => {
			return {
				...options,
				project_options: !options.project_options
			};
		});

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
