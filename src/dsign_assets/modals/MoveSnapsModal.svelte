<script>
	import MoveSnaps from 'dsign-components/components/MoveSnaps.svelte';
	import CreateProject from 'dsign-components/components/CreateProject.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';

	// actors
	import { actor_project_main, project_store } from '../store/actor_project_main';
	import { snap_store } from '../store/actor_snap_main';

	// local storage
	import { local_storage_projects } from '../store/local_storage';

	import { isMoveSnapsModalVisible } from '../store/modal';

	export let number_snaps_selected = 0;
	export let is_create_project_modal_open = false;

	function handleCloseMoveSnapsModal() {
		isMoveSnapsModalVisible.update((isMoveSnapsModalVisible) => !isMoveSnapsModalVisible);
	}

	async function handleMoveSubmit(e) {
		const { selected_project } = e.detail;

		const selected_snaps = $snap_store.snaps.filter((snap) => snap.isSelected === true);
		const selected_snaps_list = selected_snaps.map((snap) => {
			return {
				id: snap.id,
				canister_id: snap.canister_id
			};
		});

		let project_ref = {
			id: selected_project.id,
			canister_id: selected_project.canister_id
		};

		try {
			await $actor_project_main.actor.add_snaps_to_project(selected_snaps_list, project_ref);

			const { ok: all_projects, err: error } = await $actor_project_main.actor.get_all_projects();

			if (all_projects) {
				project_store.set({ isFetching: false, projects: [...all_projects] });

				local_storage_projects.set({ all_projects_count: all_projects.length || 1 });

				handleCloseMoveSnapsModal();
			}
		} catch (error) {
			console.log('call => handleMoveSubmit error: ', error);
		}
	}

	function handleOpenCreateProjectModal() {
		is_create_project_modal_open = true;
	}

	function handleCloseProjectModal() {
		is_create_project_modal_open = false;
	}

	async function handleCreateProjectSubmit(e) {
		const { project_name } = e.detail;

		try {
			const created_project_res = await $actor_project_main.actor.create_project(project_name, []);

			const { ok: all_projects, err: error } = await $actor_project_main.actor.get_all_projects();

			if (all_projects) {
				project_store.set({ isFetching: false, projects: [...all_projects] });

				local_storage_projects.set({ all_projects_count: all_projects.length || 1 });
			}

			is_create_project_modal_open = false;

			console.log('call => created_project_res: ', created_project_res);
		} catch (error) {
			console.log('call => handleCreateProjectSubmit error: ', error);
		}
	}
</script>

<div>
	<Modal on:closeModal={handleCloseMoveSnapsModal}>
		<MoveSnaps
			projects={$project_store.projects}
			{number_snaps_selected}
			on:moveSubmit={handleMoveSubmit}
			on:createProject={handleOpenCreateProjectModal}
		/>
	</Modal>
	{#if is_create_project_modal_open}
		<Modal on:closeModal={handleCloseProjectModal}>
			<CreateProject on:createProject={handleCreateProjectSubmit} />
		</Modal>
	{/if}
</div>

<style>
</style>
