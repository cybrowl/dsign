<script>
	import Modal from 'dsign-components/components/Modal.svelte';
	import SnapsMove from 'dsign-components/components/SnapsMove.svelte';

	// actors
	import { actor_project_main, actor_snap_main } from '../store/actors';

	// local storage
	import { local_storage_projects, local_storage_snaps } from '../store/local_storage';

	import { project_store, snap_store } from '../store/fetch_store';
	import { projects_tabs, is_edit_active } from '../store/page_state';
	import { modal_visible } from '../store/modal';
	import { notification, notification_visible } from '../store/notification';

	export let number_snaps_selected = 0;
	export let project = { snaps: [] };

	let hideDetails = true;
	let isMoveModal = true;

	function handleCloseSnapsMoveModal() {
		modal_visible.update((options) => {
			return {
				...options,
				snaps_move: !options.snaps_move
			};
		});

		is_edit_active.update((is_edit_active) => !is_edit_active);
	}

	function handleOpenCreateProjectModal() {
		modal_visible.update((options) => {
			return {
				...options,
				project_creation: !options.project_creation
			};
		});
	}

	async function handleMoveSubmit(e) {
		const { selected_project } = e.detail;

		handleCloseSnapsMoveModal();

		const hide_notification_delay_sec = $projects_tabs.isSnapsSelected ? 10000 : 8000;

		notification_visible.set({
			moving_snaps: true
		});

		notification.set({
			hide_delay_sec: hide_notification_delay_sec,
			project_name: selected_project.name
		});

		setTimeout(() => {
			notification_visible.set({
				moving_snaps: false
			});
		}, hide_notification_delay_sec);

		projects_tabs.set({
			isSnapsSelected: false,
			isProjectsSelected: true,
			isProjectSelected: false
		});

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

		// From Snaps
		if (selected_snaps_list.length > 0) {
			try {
				let project_ref = {
					id: selected_project.id,
					canister_id: selected_project.canister_id
				};

				await $actor_project_main.actor.add_snaps_to_project(selected_snaps_list, project_ref);

				const { ok: all_projects, err: error } = await $actor_project_main.actor.get_all_projects(
					[]
				);
				const { ok: all_snaps } = await $actor_snap_main.actor.get_all_snaps_without_project();

				if (all_projects) {
					project_store.set({ isFetching: false, projects: [...all_projects] });

					local_storage_projects.set({ all_projects_count: all_projects.length || 1 });

					notification_visible.set({
						moving_snaps: false
					});
				}

				if (all_snaps) {
					snap_store.set({ isFetching: false, snaps: [...all_snaps] });
					local_storage_snaps.set({ all_snaps_count: all_snaps.length || 1 });
				}
			} catch (error) {
				console.log('call => handleMoveSubmit error: ', error);
			}
		}

		// From Another Project
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

				const { ok: moved_snaps } = await $actor_project_main.actor.move_snaps_from_project(
					project_selected_snaps_list,
					project_from_ref,
					project_to_ref
				);

				const { ok: all_projects, err: error } = await $actor_project_main.actor.get_all_projects(
					[]
				);
				if (all_projects) {
					project_store.set({ isFetching: false, projects: [...all_projects] });

					local_storage_projects.set({ all_projects_count: all_projects.length || 1 });

					notification_visible.set({
						moving_snaps: false
					});
				}
			} catch (error) {
				console.log('call => handleMoveSubmit error: ', error);
			}
		}
	}
</script>

<Modal on:closeModal={handleCloseSnapsMoveModal}>
	<SnapsMove
		projects={[...$project_store.projects].reverse()}
		{number_snaps_selected}
		{hideDetails}
		{isMoveModal}
		on:moveSubmit={handleMoveSubmit}
		on:createProject={handleOpenCreateProjectModal}
	/>
</Modal>

<style>
</style>
