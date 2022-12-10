<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import get from 'lodash/get';

	// components
	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';

	import { actor_profile } from '$stores_ref/actors.js';
	import { local_storage_profile } from '$stores_ref/local_storage';
	import page_navigation_update, {
		page_navigation,
		navigate_to_home_with_notification
	} from '$stores_ref/page_navigation';

	// variables
	const username = get($local_storage_profile, 'username', '');

	// execution
	if (username.length > 0) {
		goto(`/profile/${username}`);
	}

	page_navigation_update.select_item(3);

	onMount(async () => {
		if ($actor_profile.loggedIn) {
			try {
				let { ok: profile, err: err_get_profile } = await $actor_profile.actor.get_profile();
				const username = get(profile, 'username', 'x');

				goto(`/profile/${username}`);
			} catch (error) {}
		} else {
			navigate_to_home_with_notification();
		}
	});
</script>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-24">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>
</main>
