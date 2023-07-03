<script>
	import { onMount, onDestroy } from 'svelte';
	import { goto } from '$app/navigation';
	import { get } from 'lodash';

	import { ProjectUpsert, Modal } from 'dsign-components';

	import { actor_project_main } from '$stores_ref/actors';
	import { auth } from '$stores_ref/auth_client';
	import { disable_project_store_reset } from '$stores_ref/page_state';
	import { navigate_to_home_with_notification } from '$stores_ref/page_navigation';
	import { project_store, projects_update } from '$stores_ref/fetch_store';
	import modal_update, { modal_mode } from '$stores_ref/modal';

	let header = '';
	let project_name_default = '';
	let loading_msg = '';
	let submit_button_label = '';
	let is_sending = false;

	if ($modal_mode.project_create) {
		header = 'Create a Project';
		loading_msg = 'Creating';
		submit_button_label = 'Create';
	} else {
		header = 'Edit Project';
		loading_msg = 'Changing to';
		project_name_default = $modal_mode.project.name;
		submit_button_label = 'Done';
	}

	onMount(async () => {
		await auth.project_main();
	});

	onDestroy(() => (is_sending = false));

	function handleCancel() {
		modal_update.change_visibility('project_upsert');
	}

	async function createProject(project_name) {
		try {
			disable_project_store_reset.set(false);

			const { ok: created_project, err: err_create_project } =
				await $actor_project_main.actor.create_project({
					name: project_name,
					description: '',
					snaps: []
				});

			const id = get(created_project, 'id', null);
			const canister_id = get(created_project, 'canister_id', null);

			if (id && canister_id) {
				goto(`/project/${id}?canister_id=${canister_id}`);
			}

			modal_update.change_visibility('project_upsert');
		} catch (error) {
			//TODO: log error
		}
	}

	async function editProject(project_name) {
		try {
			projects_update.rename_project($modal_mode.project, project_name);

			modal_update.change_visibility('project_upsert');

			let project_ref = {
				id: $modal_mode.project.id,
				canister_id: $modal_mode.project.canister_id
			};

			let { ok: updated_project, err: err_update_project_details } =
				await $actor_project_main.actor.edit_project(
					{ name: [project_name], description: [''] },
					project_ref
				);

			const { ok: all_projects, err: err_get_all_projects } =
				await $actor_project_main.actor.get_all_projects([]);

			if (all_projects) {
				project_store.set({ isFetching: false, projects: [...all_projects] });
			}
		} catch (error) {
			//TODO: log error
		}
	}

	function handleSubmit(e) {
		const { project_name } = e.detail;

		if ($actor_project_main.loggedIn) {
			if ($modal_mode.project_create) {
				is_sending = !is_sending;

				createProject(project_name);
			} else {
				editProject(project_name);
			}
		} else {
			navigate_to_home_with_notification();
		}
	}
</script>

<Modal on:closeModal={handleCancel} modalHeaderVisible={false} isModalLocked={is_sending}>
	<ProjectUpsert
		{header}
		{loading_msg}
		{is_sending}
		{project_name_default}
		{submit_button_label}
		on:cancel={handleCancel}
		on:submit={handleSubmit}
	/>
</Modal>

<style>
</style>
