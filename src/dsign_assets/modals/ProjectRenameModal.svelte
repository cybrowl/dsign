<script>
	import Modal from 'dsign-components/components/Modal.svelte';
	import ProjectRename from 'dsign-components/components/ProjectRename.svelte';

	// actors
	import { actor_project_main, project_store } from '../store/actor_project_main';

	import { modal_visible } from '../store/modal';

	export let project = {};

	function handleCloseModal() {
		modal_visible.update((options) => {
			return {
				...options,
				project_rename: !options.project_rename
			};
		});
	}

	async function handleRenameProject(e) {
		const { project_name } = e.detail;

		handleCloseModal();

		project_store.update(({ projects }) => {
			const updated_projects = projects.map((project_) => {
				if (project_.id === project.id) {
					return {
						...project_,
						name: project_name
					};
				}

				return project_;
			});

			return {
				isFetching: false,
				projects: updated_projects
			};
		});

		let project_ref = {
			id: project.id,
			canister_id: project.canister_id
		};

		let { ok: updated_project } = await $actor_project_main.actor.update_project_details(
			{ name: [project_name] },
			project_ref
		);

		const { ok: all_projects, err: error } = await $actor_project_main.actor.get_all_projects();

		if (all_projects) {
			project_store.set({ isFetching: false, projects: [...all_projects] });
		}
	}
</script>

<Modal on:closeModal={handleCloseModal}>
	<ProjectRename on:renameProject={handleRenameProject} />
</Modal>

<style>
</style>
