<script>
	import { onMount } from 'svelte';

	import get from 'lodash/get.js';

	import Modal from 'dsign-components/components/Modal.svelte';
	import SnapsMove from 'dsign-components/components/SnapsMove.svelte';

	import { actor_project_main, actor_snap_main } from '$stores_ref/actors';
	import { auth_snap_main, auth_project_main } from '$stores_ref/auth_client';
	import { local_storage_projects, local_storage_snaps } from '$stores_ref/local_storage';
	import { notification_update, notification_visible } from '$stores_ref/notification';
	import { project_store, snap_store } from '$stores_ref/fetch_store';
	import { projectsTabsState, is_edit_active } from '$stores_ref/page_state';
	import modal_update from '$stores_ref/modal';

	export let project = { snaps: [] };

	const snaps = $projectsTabsState.isSnapsSelected
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

	onMount(async () => {
		await Promise.all([auth_snap_main(), auth_project_main()]);
	});

	function handleCloseSnapsMoveModal() {
		modal_update.change_visibility('snaps_move');

		is_edit_active.update((is_edit_active) => !is_edit_active);
	}

	function handleOpenProjectCreationModal() {
		modal_update.change_visibility('project_creation');
	}

	async function handleMoveSubmit(e) {
		const { selected_project } = e.detail;

		handleCloseSnapsMoveModal();

		notification_update.show_notification_snap_move(selected_project);

		if (selected_snaps_list.length == 0) {
			//TODO: show error notification - no snaps selected
			return;
		}

		if ($actor_project_main.loggedIn && $actor_snap_main.loggedIn) {
			try {
				let project_from_ref = {
					id: project.id,
					canister_id: project.canister_id
				};

				let project_to_ref = {
					id: selected_project.id,
					canister_id: selected_project.canister_id
				};

				if ($projectsTabsState.isSnapsSelected) {
					const { ok: added_snaps_to_project, err: err_add_snaps_to_project } =
						await $actor_project_main.actor.add_snaps_to_project(
							selected_snaps_list,
							project_to_ref
						);
				} else {
					const { ok: moved_snaps, err: err_move_snaps_from_project } =
						await $actor_project_main.actor.move_snaps_from_project(
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
				//TODO: handle error
			}

			projectsTabsState.set({
				isSnapsSelected: false,
				isProjectsSelected: true,
				isProjectSelected: false
			});
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
		on:createProject={handleOpenProjectCreationModal}
	/>
</Modal>

<style>
</style>
