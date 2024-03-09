<script>
	import { onMount } from 'svelte';
	import get from 'lodash/get.js';

	import { ProjectDelete, Modal } from 'dsign-components';

	import { actor_creator } from '$stores_ref/actors';
	import { auth } from '$stores_ref/auth_client';
	import { profile_actions } from '$stores_ref/data_profile';
	import { ls_my_profile } from '$stores_ref/local_storage';

	import { navigate_to_home_with_notification } from '$stores_ref/page_navigation';
	import modal_update, { modal_mode } from '$stores_ref/modal';

	const project = get($modal_mode, 'project', '');

	function close_modal() {
		modal_update.change_visibility('project_delete');
	}

	async function delete_project() {
		await auth.creator(get($ls_my_profile, 'canister_id', ''));

		if ($actor_creator.loggedIn) {
			try {
				//TODO: delete images & files assoc with snaps

				console.log('project: ', project);

				const { ok: deleted } = await $actor_creator.actor.delete_project(project.id);

				profile_actions.delete_project(project.id);

				modal_update.change_visibility('project_delete');
			} catch (error) {
				console.log(error);
			}
		} else {
			navigate_to_home_with_notification();
		}
	}
</script>

<Modal on:closeModal={close_modal}>
	<ProjectDelete on:delete={delete_project} project_name={project.name} />
</Modal>

<style>
</style>
