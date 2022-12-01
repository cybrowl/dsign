<script>
	import get from 'lodash/get.js';

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

	export let project = { snaps: [] };

	const snaps = $projects_tabs.isSnapsSelected
		? get($snap_store, 'snaps', [])
		: get(project, 'snaps', []);

	const selected_snaps = snaps.filter((snap) => snap.isSelected === true);
	const selected_snaps_list = selected_snaps.map((snap) => {
		return {
			id: snap.id,
			canister_id: snap.canister_id
		};
	});

	let number_snaps_selected = selected_snaps.length;
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

	function showNotification(selected_project) {
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
	}

	async function handleMoveSubmit(e) {
		const { selected_project } = e.detail;

		handleCloseSnapsMoveModal();

		showNotification(selected_project);

		if (selected_snaps_list.length == 0) {
			//TODO: show error notification - no snaps selected
			return;
		}

		try {
			let project_from_ref = {
				id: project.id,
				canister_id: project.canister_id
			};

			let project_to_ref = {
				id: selected_project.id,
				canister_id: selected_project.canister_id
			};

			if ($projects_tabs.isSnapsSelected) {
				const { ok: added_snap_to_project, err: err_adding_snaps_to_projet } =
					await $actor_project_main.actor.add_snaps_to_project(selected_snaps_list, project_to_ref);
			} else {
				const { ok: moved_snaps } = await $actor_project_main.actor.move_snaps_from_project(
					selected_snaps_list,
					project_from_ref,
					project_to_ref
				);
			}

			const { ok: all_projects, err: err_all_projects } =
				await $actor_project_main.actor.get_all_projects([]);

			const { ok: all_snaps, err: err_all_snaps } =
				await $actor_snap_main.actor.get_all_snaps_without_project();

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

		projects_tabs.set({
			isSnapsSelected: false,
			isProjectsSelected: true,
			isProjectSelected: false
		});
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
