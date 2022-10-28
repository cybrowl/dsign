<script>
	import MoveSnaps from 'dsign-components/components/MoveSnaps.svelte';
	import CreateProject from 'dsign-components/components/CreateProject.svelte';
	import Modal from 'dsign-components/components/Modal.svelte';

	// actors
	import {
		actor_project_main,
		project_store,
		projects_tabs,
		is_edit_active
	} from '../store/actor_project_main';
	import { actor_snap_main, snap_store } from '../store/actor_snap_main';

	// local storage
	import { local_storage_projects, local_storage_snaps } from '../store/local_storage';

	import { is_move_snaps_modal_visible } from '../store/modal';

	export let number_snaps_selected = 0;
	export let project = { snaps: [] };
	export let is_create_project_modal_open = false;

	let hideDetails = true;
	let isMoveModal = true;

	function handleCloseMoveSnapsModal() {
		is_move_snaps_modal_visible.update(
			(is_move_snaps_modal_visible) => !is_move_snaps_modal_visible
		);
		is_edit_active.update((is_edit_active) => !is_edit_active);
	}

	function handleOpenCreateProjectModal() {
		is_create_project_modal_open = true;
	}

	function handleCloseProjectModal() {
		is_create_project_modal_open = false;
	}

	async function handleMoveSubmit(e) {
		const { selected_project } = e.detail;

		projects_tabs.set({
			isSnapsSelected: false,
			isProjectsSelected: true,
			isProjectSelected: false
		});

		handleCloseMoveSnapsModal();

		const selected_snaps = $snap_store.snaps.filter((snap) => snap.isSelected === true);
		const selected_snaps_list = selected_snaps.map((snap) => {
			return {
				id: snap.id,
				canister_id: snap.canister_id
			};
		});

		const project_selected_snaps = project.snaps.filter((snap) => snap.isSelected === true);
		const project_selected_snaps_list = project_selected_snaps.map((snap) => {
			return {
				id: snap.id,
				canister_id: snap.canister_id
			};
		});

		if (selected_snaps_list.length > 0) {
			try {
				let project_ref = {
					id: selected_project.id,
					canister_id: selected_project.canister_id
				};

				await $actor_project_main.actor.add_snaps_to_project(selected_snaps_list, project_ref);

				const { ok: all_projects, err: error } = await $actor_project_main.actor.get_all_projects();
				const { ok: all_snaps } = await $actor_snap_main.actor.get_all_snaps_without_project();

				if (all_projects) {
					project_store.set({ isFetching: false, projects: [...all_projects] });

					local_storage_projects.set({ all_projects_count: all_projects.length || 1 });
				}

				if (all_snaps) {
					snap_store.set({ isFetching: false, snaps: [...all_snaps] });
					local_storage_snaps.set({ all_snaps_count: all_snaps.length || 1 });
				}
			} catch (error) {
				console.log('call => handleMoveSubmit error: ', error);
			}
		}

		if (project_selected_snaps_list.length > 0) {
			try {
				let project_to_ref = {
					id: selected_project.id,
					canister_id: selected_project.canister_id
				};

				let project_from_ref = {
					id: project.id,
					canister_id: project.canister_id
				};

				await $actor_project_main.actor.move_snaps_from_project(
					project_selected_snaps_list,
					project_from_ref,
					project_to_ref
				);

				const { ok: all_projects, err: error } = await $actor_project_main.actor.get_all_projects();
				const { ok: all_snaps } = await $actor_snap_main.actor.get_all_snaps_without_project();
				const { ok: all_snap_ids } = await $actor_snap_main.actor.get_snap_ids();

				console.log('all_snap_ids: ', all_snap_ids);

				if (all_projects) {
					project_store.set({ isFetching: false, projects: [...all_projects] });

					local_storage_projects.set({ all_projects_count: all_projects.length || 1 });
				}

				if (all_snaps) {
					snap_store.set({ isFetching: false, snaps: [...all_snaps] });
					local_storage_snaps.set({ all_snaps_count: all_snaps.length || 1 });
				}
			} catch (error) {
				console.log('call => handleMoveSubmit error: ', error);
			}
		}
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

			console.log('is_create_project_modal_open: ', is_create_project_modal_open);
		} catch (error) {
			await $actor_project_main.actor.create_user_project_storage();
			console.log('call => handleCreateProjectSubmit error: ', error);
		}
	}
</script>

<div>
	<Modal on:closeModal={handleCloseMoveSnapsModal}>
		<MoveSnaps
			projects={[...$project_store.projects].reverse()}
			{number_snaps_selected}
			{hideDetails}
			{isMoveModal}
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
