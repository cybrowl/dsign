<script>
	import { onMount, onDestroy } from 'svelte';
	import { goto } from '$app/navigation';
	import { get } from 'lodash';

	import { ProjectUpsert, Modal } from 'dsign-components';

	import { actor_creator } from '$stores_ref/actors';
	import { auth } from '$stores_ref/auth_client';
	import { profile_store, profile_actions } from '$stores_ref/data_profile';
	import { ls_my_profile } from '$stores_ref/local_storage';

	import { navigate_to_home_with_notification } from '$stores_ref/page_navigation';
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
			const { ok: project } = await $actor_creator.actor.create_project({
				name: project_name,
				description: [project_description]
			});

			profile_actions.add_project(project);

			modal_update.change_visibility('project_upsert');
		} catch (error) {
			//TODO: log error
		}
	}

	async function edit_project(project_name, project_description) {
		try {
			//TODO: find project in `profile_store` and update it
			// profile_actions.update_project();

			modal_update.change_visibility('project_upsert');

			//TODO: edit project
		} catch (error) {
			//TODO: log error
		}
	}

	async function upsert_project(e) {
		const { project_name, project_description } = e.detail;

		await auth.creator(get($ls_my_profile, 'canister_id', ''));

		const creator_logged_in = $actor_creator.loggedIn;

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
