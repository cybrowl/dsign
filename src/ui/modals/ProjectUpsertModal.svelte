<script>
	import { onMount, onDestroy } from 'svelte';
	import { goto } from '$app/navigation';
	import { get } from 'lodash';

	import { ProjectUpsert, Modal } from 'dsign-components';

	import {} from '$stores_ref/actors';
	import { profile_store, profile_actions } from '$stores_ref/data_profile';

	import { auth } from '$stores_ref/auth_client';
	import { disable_project_store_reset } from '$stores_ref/page_state';
	import { navigate_to_home_with_notification } from '$stores_ref/page_navigation';
	import { project_store, projects_update } from '$stores_ref/fetch_store';
	import modal_update, { modal_mode } from '$stores_ref/modal';

	let content = {
		header: '',
		project_name: '',
		project_description: '',
		submit_button_label: '',
		loading_msg: ''
	};

	let is_sending = false;

	if ($modal_mode.project_create) {
		content.header = 'Create a Project';
		content.loading_msg = 'Creating';
		content.submit_button_label = 'Create';
	} else {
		content.header = 'Edit Project';
		content.loading_msg = 'Changing to';
		content.project_name = $modal_mode.project.name || '';
		content.project_description = $modal_mode.project.description || '';
		content.submit_button_label = 'Done';
	}

	function cancel_upsert_project() {
		modal_update.change_visibility('project_upsert');
	}

	async function create_project(project_name, project_description) {
		try {
			//TODO: find project in `profile_store` and update it

			//TODO: create project
			//TODO: navigate to project after it is created

			modal_update.change_visibility('project_upsert');
		} catch (error) {
			//TODO: log error
		}
	}

	async function edit_project(project_name, project_description) {
		try {
			//TODO: find project in `profile_store` and update it

			modal_update.change_visibility('project_upsert');

			//TODO: edit project
		} catch (error) {
			//TODO: log error
		}
	}

	function upsert_project(e) {
		const { project_name, project_description } = e.detail;

		const creator_logged_in = false;

		if (creator_logged_in) {
			if ($modal_mode.project_create) {
				is_sending = !is_sending;

				create_project(project_name, project_description);
			} else {
				edit_project(project_name, project_description);
			}
		} else {
			navigate_to_home_with_notification();
		}
	}
</script>

<Modal on:closeModal={cancel_upsert_project} modalHeaderVisible={false} isModalLocked={is_sending}>
	<ProjectUpsert
		{content}
		{is_sending}
		on:cancel={cancel_upsert_project}
		on:submit={upsert_project}
	/>
</Modal>

<style>
</style>
